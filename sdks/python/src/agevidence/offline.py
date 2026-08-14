"""SQLite-backed local offline queue."""

from __future__ import annotations

import json
import sqlite3
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Callable

from agevidence.ingest import ingest
from agevidence.primitives import local_digest


class Queue:
    """Persist native records and canonical projections for later flush."""

    def __init__(self, path: str | Path) -> None:
        self.path = Path(path)
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self._init()

    def put(self, record: dict[str, Any], *, primitive: str = "auto", signature: str | None = None, source: str = "agevidence_offline_queue") -> int:
        result = ingest(record, primitive=primitive)
        occurred_at = _timestamp(result.primitive)
        queued_at = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
        digest = local_digest({"native": record, "primitive": result.primitive})
        with self._connect() as connection:
            cursor = connection.execute(
                """
                INSERT INTO queue(native_payload, canonical_primitive, content_hash, occurred_at, queued_at, sync_status, attempt_count, signature, source)
                VALUES (?, ?, ?, ?, ?, 'pending', 0, ?, ?)
                """,
                (
                    json.dumps(record, sort_keys=True),
                    json.dumps(result.primitive, sort_keys=True),
                    digest,
                    occurred_at,
                    queued_at,
                    signature,
                    source,
                ),
            )
            return int(cursor.lastrowid)

    def pending(self) -> list[dict[str, Any]]:
        return self._rows("pending")

    def all(self) -> list[dict[str, Any]]:
        return self._rows(None)

    def flush(self, client: Any, *, signature_provider: Callable[[dict[str, Any]], str | None] | None = None) -> dict[str, int]:
        """Submit pending native records only when a real signer is available."""

        submitted = 0
        failed = 0
        blocked = 0
        if not hasattr(client, "submit_event") and not hasattr(client, "submit_signed_event"):
            raise TypeError("Queue.flush requires submit_event(..., signature=...) or submit_signed_event(...).")
        for row in self.pending():
            try:
                timestamp = row.get("occurred_at") or row["queued_at"]
                if hasattr(client, "submit_signed_event"):
                    client.submit_signed_event(row["native_payload"], source=row.get("source") or "agevidence_offline_queue", timestamp=timestamp)
                else:
                    signature = row.get("signature")
                    if not signature and signature_provider:
                        signature = signature_provider(row)
                    if not signature:
                        blocked += 1
                        self._record_attempt(row["local_sequence"], "pending", "signature required")
                        continue
                    client.submit_event(row["native_payload"], source=row.get("source") or "agevidence_offline_queue", timestamp=timestamp, signature=signature)
            except Exception:  # noqa: BLE001 - queue records failed attempts.
                failed += 1
                self._record_attempt(row["local_sequence"], "failed", "submission failed")
            else:
                submitted += 1
                self._record_attempt(row["local_sequence"], "synced", None)
        return {"submitted": submitted, "failed": failed, "blocked": blocked}

    def _init(self) -> None:
        with self._connect() as connection:
            connection.execute(
                """
                CREATE TABLE IF NOT EXISTS queue (
                    local_sequence INTEGER PRIMARY KEY AUTOINCREMENT,
                    native_payload TEXT NOT NULL,
                    canonical_primitive TEXT NOT NULL,
                    content_hash TEXT NOT NULL,
                    occurred_at TEXT,
                    queued_at TEXT NOT NULL,
                    sync_status TEXT NOT NULL,
                    attempt_count INTEGER NOT NULL,
                    signature TEXT,
                    source TEXT,
                    last_error TEXT
                )
                """
            )
            columns = {row[1] for row in connection.execute("PRAGMA table_info(queue)").fetchall()}
            if "signature" not in columns:
                connection.execute("ALTER TABLE queue ADD COLUMN signature TEXT")
            if "source" not in columns:
                connection.execute("ALTER TABLE queue ADD COLUMN source TEXT")
            if "last_error" not in columns:
                connection.execute("ALTER TABLE queue ADD COLUMN last_error TEXT")

    def _connect(self) -> sqlite3.Connection:
        return sqlite3.connect(self.path)

    def _rows(self, status: str | None) -> list[dict[str, Any]]:
        query = "SELECT * FROM queue" + (" WHERE sync_status = ?" if status else "") + " ORDER BY local_sequence"
        args = (status,) if status else ()
        with self._connect() as connection:
            connection.row_factory = sqlite3.Row
            rows = connection.execute(query, args).fetchall()
        result = []
        for row in rows:
            value = dict(row)
            value["native_payload"] = json.loads(value["native_payload"])
            value["canonical_primitive"] = json.loads(value["canonical_primitive"])
            result.append(value)
        return result

    def _record_attempt(self, local_sequence: int, status: str, error: str | None) -> None:
        with self._connect() as connection:
            connection.execute(
                "UPDATE queue SET sync_status = ?, attempt_count = attempt_count + 1, last_error = ? WHERE local_sequence = ?",
                (status, error, local_sequence),
            )


def _timestamp(payload: dict[str, Any]) -> str | None:
    for key in ["occurred_at", "observed_at", "effective_at", "recorded_at", "received_at", "started_at"]:
        if payload.get(key):
            return str(payload[key])
    return None

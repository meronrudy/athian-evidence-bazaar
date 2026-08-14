"""Canonical output snapshots for adapter and ingest regression tests."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from pydantic import BaseModel, ConfigDict, Field

from agevidence.ingest import ingest_file
from agevidence.primitives import canonical_json, local_digest


class SnapshotReport(BaseModel):
    model_config = ConfigDict(extra="forbid")

    path: str
    records: int
    changed: list[dict[str, Any]] = Field(default_factory=list)

    @property
    def passed(self) -> bool:
        return not self.changed


def create_snapshot(fixtures: str | Path, out: str | Path) -> SnapshotReport:
    dataset = ingest_file(fixtures)
    records = [
        {"local_digest": local_digest(result.primitive), "primitive": result.primitive}
        for result in dataset.results
    ]
    payload = {"contract_version": "athian.agevidence.snapshot.v1", "records": sorted(records, key=lambda item: item["local_digest"])}
    output = Path(out)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(canonical_json(payload) + "\n", encoding="utf-8")
    return SnapshotReport(path=str(output), records=len(records))


def check_snapshot(fixtures: str | Path, snapshot: str | Path) -> SnapshotReport:
    expected = json.loads(Path(snapshot).read_text(encoding="utf-8"))
    current_path = Path(snapshot).with_suffix(".current.json")
    report = create_snapshot(fixtures, current_path)
    current = json.loads(current_path.read_text(encoding="utf-8"))
    current_path.unlink(missing_ok=True)
    expected_records = expected.get("records", [])
    current_records = current.get("records", [])
    changes = []
    for index, (old, new) in enumerate(zip(expected_records, current_records)):
        if old != new:
            changes.append({"index": index, "old": old, "new": new})
    if len(expected_records) != len(current_records):
        changes.append({"records": {"old": len(expected_records), "new": len(current_records)}})
    report.changed = changes
    return report

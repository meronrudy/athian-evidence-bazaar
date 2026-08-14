"""Local ingest entry point."""

from __future__ import annotations

import csv
import io
import json
import re
from collections.abc import Iterable, Iterator
from pathlib import Path
from typing import Any

from pydantic import BaseModel, ConfigDict, Field, computed_field

from agevidence.errors import AgEvidenceError
from agevidence.findings import Finding, from_provenance_finding, severity_at_least
from agevidence.primitives import EvidencePrimitive
from agevidence.profiles import get_domain_profile
from agevidence.provenance import ProvenanceReport, check

from .mappings import CandidateMapping, MappingReport, build_primitive, mapping_report


class IngestResult(BaseModel):
    """Result from deterministic local ingest."""

    model_config = ConfigDict(extra="forbid")

    native: dict[str, Any]
    primitive_type: str
    confidence: str
    primitive: dict[str, Any]
    provenance: ProvenanceReport
    mapping: MappingReport
    unmapped: dict[str, Any] = Field(default_factory=dict)
    findings: list[Finding] = Field(default_factory=list)
    candidates: list[CandidateMapping]
    local_digest: str
    committed: bool = False
    profile_application: dict[str, Any] | None = None

    @computed_field
    @property
    def warnings(self) -> list[Finding]:
        return [finding for finding in self.findings if finding.severity == "warning"]

    @computed_field
    @property
    def errors(self) -> list[Finding]:
        return [finding for finding in self.findings if finding.severity in {"error", "blocking"}]

    @computed_field
    @property
    def ok(self) -> bool:
        return self.provenance.structural_validity == "pass" and not self.errors

    def explain(self):
        """Explain local evidence readiness for this result."""

        from agevidence.explain import explain

        return explain(self.primitive)

    def assess(self, profile: str):
        """Assess this result against a local evidence suitability profile."""

        from agevidence.assessment import assess

        return assess(self, profile)

    def to_dict(self) -> dict[str, Any]:
        """Return a JSON-ready dictionary."""

        return self.model_dump(mode="json")

    def to_json(self, **kwargs: Any) -> str:
        """Return a JSON string for this ingest result."""

        options = {"sort_keys": True}
        options.update(kwargs)
        return json.dumps(self.to_dict(), **options)

    def raise_for_findings(self, severity: str = "error") -> None:
        """Raise if any finding meets or exceeds the selected severity."""

        matches = [item for item in self.findings if severity_at_least(item.severity, severity)]
        if matches:
            codes = ", ".join(item.code for item in matches)
            raise AgEvidenceError(f"Ingest produced {len(matches)} finding(s) at or above {severity}: {codes}", code="INGEST_FINDINGS")


class IngestDataset(BaseModel):
    """Batch ingest result for files, streams, and dataframe-like objects."""

    model_config = ConfigDict(extra="forbid")

    results: list[IngestResult] = Field(default_factory=list)
    failures: list[Finding] = Field(default_factory=list)
    source: str | None = None

    @computed_field
    @property
    def count(self) -> int:
        return len(self.results) + len(self.failures)

    @computed_field
    @property
    def valid(self) -> int:
        return sum(1 for result in self.results if result.ok)

    @computed_field
    @property
    def invalid(self) -> int:
        return self.count - self.valid

    @computed_field
    @property
    def primitive_types(self) -> dict[str, int]:
        counts: dict[str, int] = {}
        for result in self.results:
            counts[result.primitive_type] = counts.get(result.primitive_type, 0) + 1
        return dict(sorted(counts.items()))

    @computed_field
    @property
    def findings(self) -> list[Finding]:
        values = list(self.failures)
        for result in self.results:
            values.extend(result.findings)
        return values

    @computed_field
    @property
    def coverage(self) -> dict[str, Any]:
        if not self.results:
            return {"records": self.count, "ok": 0.0, "mapping": 0.0}
        mapping = sum(result.mapping.coverage for result in self.results) / len(self.results)
        return {"records": self.count, "ok": round(self.valid / self.count, 4), "mapping": round(mapping, 4)}

    def to_primitives(self) -> list[dict[str, Any]]:
        """Return normalized primitive payloads."""

        return [result.primitive for result in self.results]


def ingest(
    record: dict[str, Any] | str | Path,
    primitive: str = "auto",
    profile: str | None = None,
    *,
    extension_namespace: str | None = None,
    ignored_fields: Iterable[str] | None = None,
) -> IngestResult:
    """Infer and normalize a native object into a local evidence primitive."""

    payload = _load(record)
    mapping = mapping_report(payload, primitive, ignored_fields=ignored_fields, extension_namespace=extension_namespace)
    primitive_type = mapping.primitive_type
    confidence = mapping.confidence if primitive == "auto" else "explicit"
    primitive_obj = build_primitive(payload, primitive_type)
    unmapped = {path: value for path in mapping.unmapped_fields if (value := _path_value(payload, path)) is not None}
    if extension_namespace and unmapped:
        primitive_obj.metadata.setdefault("extensions", {})[extension_namespace] = unmapped
    primitive_obj.metadata["agevidence_mapping"] = mapping.model_dump(mode="json", exclude_none=True, exclude_computed_fields=True)
    report = check(primitive_obj)
    profile_application = None
    if profile:
        profile_application = get_domain_profile(profile).map(primitive_obj).model_dump(mode="json", exclude_none=True)
    return IngestResult(
        native=payload,
        primitive_type=primitive_type,
        confidence=confidence,
        primitive=primitive_obj.to_payload(),
        provenance=report,
        mapping=mapping,
        unmapped=unmapped,
        findings=_findings(report, mapping),
        candidates=mapping.candidates,
        local_digest=primitive_obj.local_digest() if isinstance(primitive_obj, EvidencePrimitive) else "",
        committed=False,
        profile_application=profile_application,
    )


def ingest_many(
    records: Iterable[dict[str, Any]],
    primitive: str = "auto",
    profile: str | None = None,
    *,
    extension_namespace: str | None = None,
    ignored_fields: Iterable[str] | None = None,
    strict: bool = False,
) -> IngestDataset:
    """Ingest many native records and collect per-record failures."""

    results: list[IngestResult] = []
    failures: list[Finding] = []
    for index, record in enumerate(records):
        try:
            results.append(
                ingest(
                    record,
                    primitive=primitive,
                    profile=profile,
                    extension_namespace=extension_namespace,
                    ignored_fields=ignored_fields,
                )
            )
        except Exception as exc:  # noqa: BLE001 - batch ingest records individual failures.
            if strict:
                raise
            failures.append(
                Finding(
                    code="ingest.failed",
                    severity="blocking",
                    path=f"[{index}]",
                    message=str(exc),
                    source="ingest",
                    details={"index": index},
                )
            )
    return IngestDataset(results=results, failures=failures)


def ingest_stream(
    records: Iterable[dict[str, Any]],
    primitive: str = "auto",
    profile: str | None = None,
    *,
    extension_namespace: str | None = None,
    ignored_fields: Iterable[str] | None = None,
) -> Iterator[IngestResult]:
    """Stream local ingest results for iterable sources."""

    for record in records:
        yield ingest(record, primitive=primitive, profile=profile, extension_namespace=extension_namespace, ignored_fields=ignored_fields)


async def ingest_async(
    records: Any,
    primitive: str = "auto",
    profile: str | None = None,
    *,
    extension_namespace: str | None = None,
    ignored_fields: Iterable[str] | None = None,
):
    """Asynchronously stream local ingest results from async or sync iterables."""

    if hasattr(records, "__aiter__"):
        async for record in records:
            yield ingest(record, primitive=primitive, profile=profile, extension_namespace=extension_namespace, ignored_fields=ignored_fields)
        return
    for record in records:
        yield ingest(record, primitive=primitive, profile=profile, extension_namespace=extension_namespace, ignored_fields=ignored_fields)


def ingest_file(
    source: str | Path | Any,
    primitive: str = "auto",
    profile: str | None = None,
    *,
    extension_namespace: str | None = None,
    ignored_fields: Iterable[str] | None = None,
    strict: bool = False,
    coerce: bool = False,
) -> IngestDataset:
    """Ingest records from JSON, JSONL/NDJSON, CSV, path, or file-like object."""

    source_name, text = _read_text(source)
    records = _records_from_text(text, source_name, coerce=coerce)
    dataset = ingest_many(
        records,
        primitive=primitive,
        profile=profile,
        extension_namespace=extension_namespace,
        ignored_fields=ignored_fields,
        strict=strict,
    )
    dataset.source = source_name
    return dataset


def ingest_dataframe(
    dataframe: Any,
    primitive: str = "auto",
    profile: str | None = None,
    *,
    extension_namespace: str | None = None,
    ignored_fields: Iterable[str] | None = None,
    strict: bool = False,
) -> IngestDataset:
    """Ingest pandas- or Polars-like dataframes without hard dependencies."""

    if hasattr(dataframe, "to_dict"):
        try:
            records = dataframe.to_dict(orient="records")
        except TypeError:
            records = None
        if records is not None:
            return ingest_many(
                records,
                primitive=primitive,
                profile=profile,
                extension_namespace=extension_namespace,
                ignored_fields=ignored_fields,
                strict=strict,
            )
    if hasattr(dataframe, "to_dicts"):
        return ingest_many(
            dataframe.to_dicts(),
            primitive=primitive,
            profile=profile,
            extension_namespace=extension_namespace,
            ignored_fields=ignored_fields,
            strict=strict,
        )
    raise TypeError("Expected a pandas or Polars dataframe-like object.")


def _load(record: dict[str, Any] | str | Path) -> dict[str, Any]:
    if isinstance(record, dict):
        return record
    path = Path(record)
    return json.loads(path.read_text(encoding="utf-8"))


def _findings(report: ProvenanceReport, mapping: MappingReport) -> list[Finding]:
    findings = [from_provenance_finding(item) for item in report.findings if getattr(item, "severity", None) != "pass"]
    if mapping.unmapped_fields:
        findings.append(
            Finding(
                code="mapping.unmapped_fields",
                severity="info",
                path="native",
                message=f"{len(mapping.unmapped_fields)} native field(s) were not mapped to canonical semantics.",
                source="mapping",
                remediation={
                    "action": "review_unmapped_fields",
                    "fields": mapping.unmapped_fields,
                },
                details={"fields": mapping.unmapped_fields},
            )
        )
    return findings


def _read_text(source: str | Path | Any) -> tuple[str, str]:
    if hasattr(source, "read"):
        raw = source.read()
        text = raw.decode("utf-8") if isinstance(raw, bytes) else str(raw)
        return (str(getattr(source, "name", "<stream>")), text)
    path = Path(source)
    return (str(path), path.read_text(encoding="utf-8"))


def _records_from_text(text: str, source_name: str, *, coerce: bool = False) -> list[dict[str, Any]]:
    suffix = Path(source_name).suffix.lower()
    if suffix == ".csv":
        records = [dict(row) for row in csv.DictReader(io.StringIO(text))]
        return [_coerce_record(record) for record in records] if coerce else records
    if suffix in {".jsonl", ".ndjson"}:
        return _json_lines(text)
    try:
        loaded = json.loads(text)
    except json.JSONDecodeError:
        return _json_lines(text)
    if isinstance(loaded, list):
        return [_ensure_record(item) for item in loaded]
    if isinstance(loaded, dict):
        return [loaded]
    raise ValueError("Ingest files must contain a JSON object, JSON array, JSONL/NDJSON records, or CSV rows.")


def _json_lines(text: str) -> list[dict[str, Any]]:
    records: list[dict[str, Any]] = []
    for line_number, line in enumerate(text.splitlines(), start=1):
        if not line.strip():
            continue
        try:
            records.append(_ensure_record(json.loads(line)))
        except json.JSONDecodeError as exc:
            raise ValueError(f"Invalid JSONL record on line {line_number}: {exc}") from exc
    return records


def _ensure_record(value: Any) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise ValueError("Each ingest record must be a JSON object.")
    return value


def _coerce_record(record: dict[str, Any]) -> dict[str, Any]:
    return {key: _coerce_scalar(value) for key, value in record.items()}


def _coerce_scalar(value: Any) -> Any:
    if not isinstance(value, str):
        return value
    text = value.strip()
    if text == "":
        return None
    lowered = text.lower()
    if lowered == "true":
        return True
    if lowered == "false":
        return False
    if lowered == "null":
        return None
    if text.startswith(("{", "[", '"')):
        try:
            return json.loads(text)
        except json.JSONDecodeError:
            return value
    try:
        if re.fullmatch(r"[-+]?\d+", text):
            return int(text)
        if re.fullmatch(r"[-+]?(?:\d+\.\d*|\d*\.\d+)(?:[eE][-+]?\d+)?", text) or re.fullmatch(r"[-+]?\d+[eE][-+]?\d+", text):
            return float(text)
    except ValueError:
        return value
    return value


def _path_value(payload: dict[str, Any], path: str) -> Any:
    if "[]" in path:
        return _array_path_values(payload, path)
    current: Any = payload
    for part in path.split("."):
        if not isinstance(current, dict) or part not in current:
            return None
        current = current[part]
    return current


def _array_path_values(payload: dict[str, Any], path: str) -> Any:
    head, _, tail = path.partition("[]")
    values = _path_value(payload, head)
    if not isinstance(values, list):
        return None
    child_path = tail.removeprefix(".")
    if not child_path:
        return values
    result = []
    for item in values:
        if isinstance(item, dict):
            child = _path_value(item, child_path)
            if child is not None:
                result.append(child)
    return result

"""Local bundle builder orchestration."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from pydantic import BaseModel, ConfigDict, Field, computed_field

from agevidence.findings import Finding
from agevidence.primitives import EvidencePrimitive, canonical_json, local_digest
from agevidence.provenance import check


LOCAL_BUNDLE_CONTRACT_VERSION = "athian.agevidence.bundle.local.v1"

SCHEMA_BY_PRIMITIVE = {
    "SourceRecord": "athian.agevidence.source_record.v1",
    "Observation": "athian.agevidence.observation.v1",
    "SpatialObservation": "athian.agevidence.spatial_observation.v1",
    "InterventionEvent": "athian.agevidence.intervention_event.v1",
    "OperationalEvent": "athian.agevidence.operational_event.v1",
    "ModelRun": "athian.agevidence.model_run.v1",
    "CalibrationRecord": "athian.agevidence.calibration_record.v1",
    "ProductLot": "athian.agevidence.product_lot.v1",
    "AssetState": "athian.agevidence.asset_state.v1",
    "DerivedObservation": "athian.agevidence.derived_observation.v1",
    "Transformation": "athian.agevidence.transformation.v1",
    "Attachment": "athian.agevidence.attachment.v1",
    "ExternalObject": "athian.agevidence.external_object.v1",
}


class BundleSummary(BaseModel):
    """Human- and machine-readable bundle summary."""

    model_config = ConfigDict(extra="forbid")

    records: int
    primitive_types: dict[str, int] = Field(default_factory=dict)
    sources: list[str] = Field(default_factory=list)
    period: dict[str, str | None] = Field(default_factory=dict)
    integrity: str = "not_verified"
    interpretation: str = "none"


class BundleValidationReport(BaseModel):
    """Local bundle manifest validation report."""

    model_config = ConfigDict(extra="forbid")

    manifest_records: int = 0
    findings: list[Finding] = Field(default_factory=list)

    @computed_field
    @property
    def passed(self) -> bool:
        return not any(finding.severity in {"error", "blocking"} for finding in self.findings)


class Bundle(BaseModel):
    """Local Python bundle builder.

    This class assembles deterministic manifests and delegates trust operations
    to Rust. It does not sign receipts or cryptographically verify bundles.
    """

    model_config = ConfigDict(extra="forbid")

    items: list[dict[str, Any]] = Field(default_factory=list)

    def add(self, value: Any) -> "Bundle":
        """Add primitives, ingest results, frames, datasets, or iterables."""

        self.items.extend(_payloads(value))
        return self

    def validate(self) -> list[dict[str, Any]]:
        """Return local provenance reports for bundle items."""

        return [check(item).model_dump(mode="json") for item in self.items]

    def validate_manifest(self, manifest: dict[str, Any] | None = None) -> BundleValidationReport:
        """Validate a deterministic local bundle manifest."""

        return validate_manifest(manifest or self.to_manifest())

    def to_primitives(self) -> list[dict[str, Any]]:
        return list(self.items)

    def to_manifest(self) -> dict[str, Any]:
        """Return a deterministic local bundle manifest."""

        normalized = sorted(self.items, key=lambda item: local_digest(item))
        return {
            "contract_version": LOCAL_BUNDLE_CONTRACT_VERSION,
            "records": [
                {
                    "local_digest": local_digest(item),
                    "schema_id": item.get("schema_id"),
                    "primitive_type": item.get("primitive_type"),
                    "payload": item,
                }
                for item in normalized
            ],
            "authority_boundary": (
                "Python bundle manifests are local orchestration artifacts. "
                "Canonical commitments, signatures, and bundle verification stay behind the Rust trust boundary."
            ),
        }

    def write(self, path: str | Path) -> Path:
        """Write the deterministic manifest to disk."""

        output = Path(path)
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(canonical_json(self.to_manifest()) + "\n", encoding="utf-8")
        return output

    def verify(self, path: str | Path | None = None):
        """Delegate verification to the Rust verifier facade."""

        from agevidence.verify import verify

        if path is None:
            import tempfile

            with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False) as file:
                file.write(json.dumps(self.to_manifest(), sort_keys=True))
                path = Path(file.name)
        return verify(path)

    def summary(self) -> BundleSummary:
        counts: dict[str, int] = {}
        sources: set[str] = set()
        timestamps: list[str] = []
        for item in self.items:
            primitive_type = str(item.get("primitive_type") or "Unknown")
            counts[primitive_type] = counts.get(primitive_type, 0) + 1
            if item.get("source_system"):
                sources.add(str(item["source_system"]))
            for source in item.get("source_records", []) if isinstance(item.get("source_records"), list) else []:
                if isinstance(source, dict) and source.get("source_system"):
                    sources.add(str(source["source_system"]))
            for key in ["observed_at", "occurred_at", "effective_at", "recorded_at", "received_at", "started_at", "completed_at"]:
                if item.get(key):
                    timestamps.append(str(item[key]))
        return BundleSummary(
            records=len(self.items),
            primitive_types=dict(sorted(counts.items())),
            sources=sorted(sources),
            period={"start": min(timestamps) if timestamps else None, "end": max(timestamps) if timestamps else None},
        )

    def assess(self, profile: str):
        from agevidence.assessment import assess

        return assess(self, profile)


def validate_manifest_file(path: str | Path) -> BundleValidationReport:
    """Validate a local bundle manifest file."""

    return validate_manifest(json.loads(Path(path).read_text(encoding="utf-8")))


def validate_manifest(manifest: dict[str, Any]) -> BundleValidationReport:
    """Validate local bundle manifest determinism and primitive consistency."""

    findings: list[Finding] = []
    records = manifest.get("records")
    if manifest.get("contract_version") != LOCAL_BUNDLE_CONTRACT_VERSION:
        findings.append(
            Finding(
                code="bundle.contract_version_invalid",
                severity="error",
                path="contract_version",
                message=f"Bundle manifest contract_version must be {LOCAL_BUNDLE_CONTRACT_VERSION}.",
                source="bundle",
            )
        )
    if not isinstance(records, list):
        findings.append(Finding(code="bundle.records_invalid", severity="error", path="records", message="Bundle manifest records must be a list.", source="bundle"))
        return BundleValidationReport(manifest_records=0, findings=findings)

    digests = [record.get("local_digest") for record in records if isinstance(record, dict)]
    if digests != sorted(digests):
        findings.append(Finding(code="bundle.records_not_sorted", severity="error", path="records", message="Bundle records must be sorted by local_digest.", source="bundle"))
    duplicates = sorted({digest for digest in digests if digest and digests.count(digest) > 1})
    for digest in duplicates:
        findings.append(Finding(code="bundle.duplicate_digest", severity="error", path="records", message=f"Duplicate bundle record digest: {digest}.", source="bundle"))

    for index, record in enumerate(records):
        path = f"records[{index}]"
        if not isinstance(record, dict):
            findings.append(Finding(code="bundle.record_invalid", severity="error", path=path, message="Bundle record must be an object.", source="bundle"))
            continue
        payload = record.get("payload")
        if not isinstance(payload, dict):
            findings.append(Finding(code="bundle.payload_invalid", severity="error", path=f"{path}.payload", message="Bundle record payload must be an object.", source="bundle"))
            continue
        expected_digest = local_digest(payload)
        if record.get("local_digest") != expected_digest:
            findings.append(Finding(code="bundle.digest_mismatch", severity="error", path=f"{path}.local_digest", message="Bundle record local_digest does not match payload.", source="bundle"))
        if record.get("schema_id") != payload.get("schema_id"):
            findings.append(Finding(code="bundle.schema_id_mismatch", severity="error", path=f"{path}.schema_id", message="Manifest schema_id must match payload schema_id.", source="bundle"))
        if record.get("primitive_type") != payload.get("primitive_type"):
            findings.append(Finding(code="bundle.primitive_type_mismatch", severity="error", path=f"{path}.primitive_type", message="Manifest primitive_type must match payload primitive_type.", source="bundle"))
        primitive_type = payload.get("primitive_type")
        expected_schema = SCHEMA_BY_PRIMITIVE.get(str(primitive_type))
        if expected_schema and payload.get("schema_id") != expected_schema:
            findings.append(Finding(code="bundle.primitive_schema_mismatch", severity="error", path=f"{path}.payload.schema_id", message=f"{primitive_type} payload must use schema_id {expected_schema}.", source="bundle"))
        report = check(payload)
        if report.structural_validity != "pass":
            findings.append(Finding(code="bundle.payload_structural_invalid", severity="error", path=f"{path}.payload", message=f"{primitive_type or 'Unknown'} payload failed local structural validation.", source="bundle", details=report.model_dump(mode="json")))
    return BundleValidationReport(manifest_records=len(records), findings=findings)


def _payloads(value: Any) -> list[dict[str, Any]]:
    if value is None:
        return []
    if hasattr(value, "to_primitives"):
        return list(value.to_primitives())
    if hasattr(value, "results"):
        return [result.primitive for result in value.results]
    if hasattr(value, "primitive"):
        return [dict(value.primitive)]
    if isinstance(value, EvidencePrimitive):
        return [value.to_payload()]
    if isinstance(value, dict):
        return [value]
    if isinstance(value, list) or (hasattr(value, "__iter__") and not isinstance(value, (str, bytes, bytearray))):
        payloads: list[dict[str, Any]] = []
        for item in value:
            payloads.extend(_payloads(item))
        return payloads
    raise TypeError("Unsupported bundle item.")

"""Deterministic primitive inference rules."""

from __future__ import annotations

import re
from collections.abc import Iterable
from typing import Any, Literal

from pydantic import BaseModel, ConfigDict, Field, computed_field

from agevidence.primitives import (
    AssetState,
    Attachment,
    CalibrationRecord,
    DerivedObservation,
    ExternalObject,
    InterventionEvent,
    ModelRun,
    Observation,
    OperationalEvent,
    ProductLot,
    SourceRecord,
    SpatialObservation,
    Transformation,
)


REVERSE_DNS_RE = re.compile(r"^[A-Za-z][A-Za-z0-9-]*(?:\.[A-Za-z0-9][A-Za-z0-9-]*)+$")

SPECIAL_NATIVE_FIELDS = {
    "schema_id",
    "primitive_type",
    "metadata",
    "limitations",
}

FIELD_SPECS: dict[str, dict[str, list[str]]] = {
    "SourceRecord": {
        "source_system": ["source_system", "system"],
        "record_id": ["record_id", "document_id", "id"],
        "observed_at": ["observed_at", "recorded_at", "timestamp", "measured_at"],
        "controlled_uri": ["controlled_uri"],
        "commitment": ["commitment"],
    },
    "Observation": {
        "subject": ["subject", "subject_id", "animal_id", "target"],
        "observable": ["observable", "measurement", "metric", "type"],
        "value": ["value", "measurement_value"],
        "unit": ["unit", "uom"],
        "observed_at": ["observed_at", "measured_at", "timestamp", "occurred_at"],
        "instrument": ["instrument", "sensor", "device", "instrument_id", "sensor_id", "device_id"],
        "method": ["method"],
        "source_records": ["source_records"],
    },
    "SpatialObservation": {
        "geometry": ["geometry"],
        "observable": ["observable", "measurement", "metric"],
        "value": ["value", "measurement_value"],
        "unit": ["unit", "uom"],
        "observed_at": ["observed_at", "measured_at", "timestamp"],
        "crs": ["crs", "coordinate_reference_system"],
        "subject": ["subject"],
        "source_records": ["source_records"],
    },
    "InterventionEvent": {
        "target": ["target", "subject", "herd", "asset"],
        "intervention": ["intervention", "product", "intervention_type"],
        "quantity": ["quantity", "dose", "amount"],
        "unit": ["unit", "uom"],
        "occurred_at": ["occurred_at", "timestamp", "applied_at"],
        "batch": ["batch", "lot", "product_batch"],
        "source_records": ["source_records"],
    },
    "OperationalEvent": {
        "machine": ["machine", "machine_id", "vehicle", "asset"],
        "operation": ["operation", "operation_type", "activity"],
        "started_at": ["started_at", "start_time", "timestamp"],
        "completed_at": ["completed_at", "end_time", "finished_at"],
        "location": ["location"],
        "source_records": ["source_records"],
    },
    "ModelRun": {
        "model_id": ["model_id", "base_model_id"],
        "model_version": ["model_version", "version"],
        "implementation_digest": ["implementation_digest", "weights_digest"],
        "input_commitments": ["input_commitments", "source_document_commitments"],
        "parameters": ["parameters", "generation_config"],
        "execution_environment": ["execution_environment", "runtime"],
        "started_at": ["started_at", "executed_at", "execution_timestamp", "timestamp"],
        "completed_at": ["completed_at", "executed_at", "execution_timestamp", "timestamp"],
        "outputs": ["outputs"],
        "verification": ["verification"],
        "inputs": ["inputs"],
    },
    "CalibrationRecord": {
        "instrument": ["instrument", "instrument_id", "sensor_id", "device_id"],
        "calibrated_at": ["calibrated_at", "calibration_timestamp", "timestamp"],
        "valid_until": ["valid_until", "expires_at"],
        "procedure": ["procedure", "calibration_procedure"],
        "standard": ["standard", "calibration_standard"],
        "certificate_hash": ["certificate_hash", "certificate_sha256"],
        "source_records": ["source_records"],
    },
    "ProductLot": {
        "product": ["product", "product_id", "material", "material_id"],
        "lot": ["lot", "lot_id", "batch", "product_lot_id"],
        "manufacturer": ["manufacturer", "maker"],
        "manufactured_at": ["manufactured_at", "manufacture_date"],
        "expiry": ["expiry", "expires_at", "valid_until"],
        "quantity": ["quantity", "amount"],
        "unit": ["unit", "uom"],
        "source_records": ["source_records"],
    },
    "AssetState": {
        "asset": ["asset", "asset_id", "device_id", "machine"],
        "state": ["state", "status"],
        "effective_at": ["effective_at", "timestamp", "observed_at"],
        "valid_until": ["valid_until", "expires_at"],
        "source_records": ["source_records"],
    },
    "DerivedObservation": {
        "subject": ["subject", "subject_id", "animal_id", "target"],
        "observable": ["observable", "measurement", "metric", "type"],
        "value": ["value", "measurement_value"],
        "unit": ["unit", "uom"],
        "observed_at": ["observed_at", "measured_at", "timestamp", "occurred_at"],
        "inputs": ["inputs", "input_commitments"],
        "transformation": ["transformation"],
        "derived_at": ["derived_at", "generated_at"],
        "source_records": ["source_records"],
    },
    "Transformation": {
        "name": ["name", "transformation_name"],
        "version": ["version", "transformation_version"],
        "implementation": ["implementation", "implementation_id"],
        "parameters": ["parameters"],
    },
    "Attachment": {
        "path": ["path", "file_path"],
        "media_type": ["media_type", "content_type", "mime_type"],
        "sha256": ["sha256", "content_sha256"],
        "size": ["size", "bytes"],
        "name": ["name", "filename"],
    },
    "ExternalObject": {
        "uri": ["uri", "url", "href"],
        "sha256": ["sha256", "content_sha256"],
        "size": ["size", "bytes"],
        "media_type": ["media_type", "content_type", "mime_type"],
        "name": ["name", "filename"],
    },
}

REQUIRED_FIELDS: dict[str, list[str]] = {
    "SourceRecord": ["source_system", "record_id", "observed_at"],
    "Observation": ["subject", "observable", "value", "unit", "observed_at"],
    "SpatialObservation": ["geometry", "observable", "value", "unit", "observed_at"],
    "InterventionEvent": ["target", "intervention", "quantity", "unit", "occurred_at"],
    "OperationalEvent": ["machine", "operation", "started_at", "completed_at"],
    "ModelRun": ["model_id", "model_version", "inputs", "outputs"],
    "CalibrationRecord": ["instrument", "calibrated_at"],
    "ProductLot": ["product", "lot"],
    "AssetState": ["asset", "state", "effective_at"],
    "DerivedObservation": ["subject", "observable", "value", "unit", "observed_at", "inputs", "transformation"],
    "Transformation": ["name", "version"],
    "Attachment": ["path", "media_type"],
    "ExternalObject": ["uri", "sha256"],
}

ANCHORS: dict[str, list[list[str]]] = {
    "SpatialObservation": [["geometry"]],
    "ModelRun": [["model_id", "base_model_id"]],
    "InterventionEvent": [["intervention", "product", "intervention_type"]],
    "OperationalEvent": [["machine", "machine_id", "vehicle"]],
    "CalibrationRecord": [["calibrated_at", "calibration_timestamp"]],
    "ProductLot": [["lot", "lot_id", "batch", "product_lot_id"]],
    "AssetState": [["asset", "asset_id", "device_id", "machine"], ["state", "status"]],
    "DerivedObservation": [["inputs", "input_commitments"], ["transformation"]],
    "Transformation": [["name", "transformation_name"], ["version", "transformation_version"]],
    "Attachment": [["path", "file_path"], ["media_type", "content_type", "mime_type"]],
    "ExternalObject": [["uri", "url", "href"], ["sha256", "content_sha256"]],
}


class CandidateMapping(BaseModel):
    """A candidate primitive mapping produced by deterministic rules."""

    model_config = ConfigDict(extra="forbid")

    primitive_type: str
    confidence: str
    score: int
    matched_fields: list[str]


class FieldMapping(BaseModel):
    """One native-field to canonical-field mapping."""

    model_config = ConfigDict(extra="forbid")

    source_field: str | None
    canonical_field: str
    source_path: str | None = None
    canonical_path: str | None = None
    confidence: str
    required: bool = True
    matched: bool = True
    transformation: str = "copy"


class SourceFieldCoverage(BaseModel):
    """Path-aware coverage classification for one native source field path."""

    model_config = ConfigDict(extra="forbid")

    source_field: str
    status: Literal["canonical_mapped", "extension_preserved", "explicitly_ignored", "silently_lost"]
    canonical_field: str | None = None


class MappingReport(BaseModel):
    """Mapping coverage for one native payload."""

    model_config = ConfigDict(extra="forbid")

    primitive_type: str
    confidence: str
    score: int
    field_mappings: list[FieldMapping] = Field(default_factory=list)
    unmapped_fields: list[str] = Field(default_factory=list)
    ignored_fields: list[str] = Field(default_factory=list)
    extension_preserved_fields: list[str] = Field(default_factory=list)
    field_coverage: list[SourceFieldCoverage] = Field(default_factory=list)
    candidates: list[CandidateMapping] = Field(default_factory=list)

    @computed_field
    @property
    def mapped_fields(self) -> list[str]:
        return [item.canonical_field for item in self.field_mappings if item.matched]

    @computed_field
    @property
    def mapped_source_fields(self) -> list[str]:
        return [item.source_path or item.source_field for item in self.field_mappings if item.source_path or item.source_field]

    @computed_field
    @property
    def mapped_count(self) -> int:
        return len(self.mapped_fields)

    @computed_field
    @property
    def source_field_count(self) -> int:
        if self.field_coverage:
            return len(self.field_coverage)
        return len(set(self.mapped_source_fields) | set(self.unmapped_fields) | set(self.ignored_fields))

    @computed_field
    @property
    def coverage(self) -> float:
        total = self.source_field_count
        if total == 0:
            return 1.0
        if self.field_coverage:
            covered = sum(1 for item in self.field_coverage if item.status != "silently_lost")
            return round(covered / total, 4)
        covered = len(set(self.mapped_source_fields) | set(self.extension_preserved_fields) | set(self.ignored_fields))
        return round(covered / total, 4)

    @computed_field
    @property
    def silently_lost_fields(self) -> list[str]:
        return [item.source_field for item in self.field_coverage if item.status == "silently_lost"]

    def explain(self) -> str:
        """Return a concise mapping explanation."""

        return (
            f"{self.primitive_type} ({self.confidence}, {self.score}): "
            f"{self.mapped_count} canonical fields mapped, "
            f"{len(self.unmapped_fields)} native fields unmapped."
        )


def candidate_mappings(payload: dict[str, Any]) -> list[CandidateMapping]:
    """Return possible primitive mappings ordered by confidence."""

    candidates = [
        _candidate(payload, "SpatialObservation"),
        _candidate(payload, "DerivedObservation"),
        _candidate(payload, "ModelRun"),
        _candidate(payload, "InterventionEvent"),
        _candidate(payload, "OperationalEvent"),
        _candidate(payload, "CalibrationRecord"),
        _candidate(payload, "ProductLot"),
        _candidate(payload, "AssetState"),
        _candidate(payload, "Transformation"),
        _candidate(payload, "Attachment"),
        _candidate(payload, "ExternalObject"),
        _candidate(payload, "Observation"),
        _candidate(payload, "SourceRecord"),
    ]
    filtered = [candidate for candidate in candidates if candidate.score > 0]
    return sorted(filtered, key=lambda item: item.score, reverse=True)


def mapping_report(
    payload: dict[str, Any],
    primitive_type: str = "auto",
    *,
    ignored_fields: Iterable[str] | None = None,
    extension_namespace: str | None = None,
) -> MappingReport:
    """Return deterministic mapping coverage for one native payload."""

    ignored = set(ignored_fields or [])
    if extension_namespace:
        validate_extension_namespace(extension_namespace)
    candidates = candidate_mappings(payload)
    if primitive_type == "auto":
        if not candidates:
            raise ValueError("No primitive mapping matched this payload.")
        selected = candidates[0]
    else:
        selected = next((item for item in candidates if item.primitive_type == primitive_type), None) or _candidate(payload, primitive_type)

    field_mappings = _field_mappings(payload, selected.primitive_type)
    source_paths = [path for path in _source_field_paths(payload) if not _special_path(path)]
    mapped_sources = {item.source_path or item.source_field for item in field_mappings if item.source_path or item.source_field}
    mapped_paths = {
        path
        for path in source_paths
        if any(_path_covers(source, path) for source in mapped_sources if source is not None)
    }
    ignored_paths = {
        path
        for path in source_paths
        if any(_path_covers(pattern, path) for pattern in ignored)
    }
    unmapped = sorted(
        path
        for path in source_paths
        if path not in mapped_paths and path not in ignored_paths
    )
    extension_preserved = unmapped if extension_namespace else []
    coverage = _field_coverage(source_paths, field_mappings, mapped_paths, ignored_paths, set(extension_preserved))
    return MappingReport(
        primitive_type=selected.primitive_type,
        confidence=selected.confidence,
        score=selected.score,
        field_mappings=field_mappings,
        unmapped_fields=unmapped,
        ignored_fields=sorted(ignored_paths),
        extension_preserved_fields=extension_preserved,
        field_coverage=coverage,
        candidates=candidates,
    )


def validate_extension_namespace(namespace: str) -> str:
    """Validate a reverse-DNS extension namespace."""

    if not REVERSE_DNS_RE.match(namespace):
        raise ValueError("Extension namespace must be a reverse-DNS string, for example com.example.source.")
    return namespace


def build_primitive(payload: dict[str, Any], primitive_type: str):
    """Build a primitive from a native JSON payload using known aliases."""

    if primitive_type == "SourceRecord":
        return SourceRecord(
            source_system=_first(payload, "source_system", "system", default="unknown"),
            record_id=_first(payload, "record_id", "document_id", "id"),
            observed_at=_first(payload, "observed_at", "recorded_at", "timestamp", "measured_at"),
            controlled_uri=payload.get("controlled_uri"),
            commitment=payload.get("commitment"),
            metadata=_metadata(payload),
        )
    if primitive_type == "Observation":
        return Observation(
            subject=_first(payload, "subject", "subject_id", "animal_id", "target"),
            observable=_first(payload, "observable", "measurement", "metric", "type", default="measurement"),
            value=_first(payload, "value", "measurement_value"),
            unit=_first(payload, "unit", "uom"),
            observed_at=_first(payload, "observed_at", "measured_at", "timestamp", "occurred_at"),
            instrument=_instrument(payload),
            method=payload.get("method"),
            source_records=_source_records(payload),
            metadata=_metadata(payload),
        )
    if primitive_type == "SpatialObservation":
        return SpatialObservation(
            geometry=payload["geometry"],
            observable=_first(payload, "observable", "measurement", "metric", default="spatial_measurement"),
            value=_first(payload, "value", "measurement_value"),
            unit=_first(payload, "unit", "uom"),
            observed_at=_first(payload, "observed_at", "measured_at", "timestamp"),
            crs=_first(payload, "crs", "coordinate_reference_system", default="EPSG:4326"),
            subject=payload.get("subject"),
            source_records=_source_records(payload),
            metadata=_metadata(payload),
        )
    if primitive_type == "InterventionEvent":
        return InterventionEvent(
            target=_first(payload, "target", "subject", "herd", "asset"),
            intervention=_first(payload, "intervention", "product", "intervention_type"),
            quantity=_first(payload, "quantity", "dose", "amount"),
            unit=_first(payload, "unit", "uom"),
            occurred_at=_first(payload, "occurred_at", "timestamp", "applied_at"),
            batch=_first(payload, "batch", "lot", "product_batch", default=None),
            source_records=_source_records(payload),
            metadata=_metadata(payload),
        )
    if primitive_type == "OperationalEvent":
        return OperationalEvent(
            machine=_first(payload, "machine", "machine_id", "vehicle", "asset"),
            operation=_first(payload, "operation", "operation_type", "activity"),
            started_at=_first(payload, "started_at", "start_time", "timestamp"),
            completed_at=_first(payload, "completed_at", "end_time", "finished_at"),
            location=payload.get("location"),
            source_records=_source_records(payload),
            metadata=_metadata(payload),
        )
    if primitive_type == "ModelRun":
        return ModelRun(
            model_id=_first(payload, "model_id", "base_model_id"),
            model_version=_first(payload, "model_version", "version", default="unknown"),
            implementation_digest=_first(payload, "implementation_digest", "weights_digest", default=None),
            input_commitments=list(payload.get("input_commitments") or payload.get("source_document_commitments") or []),
            parameters=dict(payload.get("parameters") or payload.get("generation_config") or {}),
            execution_environment=dict(payload.get("execution_environment") or ({"runtime": payload["runtime"]} if payload.get("runtime") else {})),
            started_at=_first(payload, "started_at", "executed_at", "execution_timestamp", "timestamp", default=None),
            completed_at=_first(payload, "completed_at", "executed_at", "execution_timestamp", "timestamp", default=None),
            inputs=list(payload.get("inputs", [])),
            outputs=list(payload.get("outputs", [])),
            executed_at=_first(payload, "executed_at", "execution_timestamp", "timestamp", default=None),
            weights_digest=payload.get("weights_digest"),
            adapter_id=payload.get("adapter_id"),
            adapter_digest=payload.get("adapter_digest"),
            model_license=payload.get("model_license"),
            runtime=payload.get("runtime"),
            generation_config=dict(payload.get("generation_config", {})),
            system_prompt_digest=payload.get("system_prompt_digest"),
            retrieval_corpus_digest=payload.get("retrieval_corpus_digest"),
            source_document_commitments=list(payload.get("source_document_commitments", [])),
            normalized_output_digest=payload.get("normalized_output_digest"),
            policy_version=payload.get("policy_version"),
            issuer=payload.get("issuer"),
            signer=payload.get("signer"),
            verification=dict(payload.get("verification") or {}),
            limitations=list(payload.get("limitations", [])),
            metadata=_metadata(payload),
        )
    if primitive_type == "CalibrationRecord":
        return CalibrationRecord(
            instrument=_first(payload, "instrument", "instrument_id", "sensor_id", "device_id"),
            calibrated_at=_first(payload, "calibrated_at", "calibration_timestamp", "timestamp"),
            valid_until=_first(payload, "valid_until", "expires_at", default=None),
            procedure=_first(payload, "procedure", "calibration_procedure", default=None),
            standard=_first(payload, "standard", "calibration_standard", default=None),
            certificate_hash=_first(payload, "certificate_hash", "certificate_sha256", default=None),
            source_records=_source_records(payload),
            metadata=_metadata(payload),
        )
    if primitive_type == "ProductLot":
        return ProductLot(
            product=_first(payload, "product", "product_id", "material", "material_id"),
            lot=_first(payload, "lot", "lot_id", "batch", "product_lot_id"),
            manufacturer=_first(payload, "manufacturer", "maker", default=None),
            manufactured_at=_first(payload, "manufactured_at", "manufacture_date", default=None),
            expiry=_first(payload, "expiry", "expires_at", "valid_until", default=None),
            quantity=_first(payload, "quantity", "amount", default=None),
            unit=_first(payload, "unit", "uom", default=None),
            source_records=_source_records(payload),
            metadata=_metadata(payload),
        )
    if primitive_type == "AssetState":
        state = _first(payload, "state", default=None)
        return AssetState(
            asset=_first(payload, "asset", "asset_id", "device_id", "machine"),
            state=state if isinstance(state, dict) else {"status": _first(payload, "status", default=state)},
            effective_at=_first(payload, "effective_at", "timestamp", "observed_at"),
            valid_until=_first(payload, "valid_until", "expires_at", default=None),
            source_records=_source_records(payload),
            metadata=_metadata(payload),
        )
    if primitive_type == "DerivedObservation":
        return DerivedObservation(
            subject=_first(payload, "subject", "subject_id", "animal_id", "target"),
            observable=_first(payload, "observable", "measurement", "metric", "type", default="measurement"),
            value=_first(payload, "value", "measurement_value"),
            unit=_first(payload, "unit", "uom"),
            observed_at=_first(payload, "observed_at", "measured_at", "timestamp", "occurred_at"),
            inputs=list(_first(payload, "inputs", "input_commitments", default=[])),
            transformation=_first(payload, "transformation"),
            derived_at=_first(payload, "derived_at", "generated_at", default=None),
            source_records=_source_records(payload),
            metadata=_metadata(payload),
        )
    if primitive_type == "Transformation":
        return Transformation(
            name=_first(payload, "name", "transformation_name"),
            version=_first(payload, "version", "transformation_version"),
            implementation=_first(payload, "implementation", "implementation_id", default=None),
            parameters=dict(_first(payload, "parameters", default={}) or {}),
            metadata=_metadata(payload),
        )
    if primitive_type == "Attachment":
        return Attachment(
            path=_first(payload, "path", "file_path"),
            media_type=_first(payload, "media_type", "content_type", "mime_type"),
            sha256=_first(payload, "sha256", "content_sha256", default=None),
            size=_first(payload, "size", "bytes", default=None),
            name=_first(payload, "name", "filename", default=None),
            metadata=_metadata(payload),
        )
    if primitive_type == "ExternalObject":
        return ExternalObject(
            uri=_first(payload, "uri", "url", "href"),
            sha256=_first(payload, "sha256", "content_sha256"),
            size=_first(payload, "size", "bytes", default=None),
            media_type=_first(payload, "media_type", "content_type", "mime_type", default=None),
            name=_first(payload, "name", "filename", default=None),
            metadata=_metadata(payload),
        )
    raise ValueError(f"Unknown primitive type: {primitive_type}")


def _candidate(payload: dict[str, Any], primitive_type: str) -> CandidateMapping:
    fields = REQUIRED_FIELDS.get(primitive_type, [])
    if not fields:
        return CandidateMapping(primitive_type=primitive_type, confidence="low", score=0, matched_fields=[])
    specs = FIELD_SPECS.get(primitive_type, {})
    for anchor_group in ANCHORS.get(primitive_type, []):
        if not any(_present(_get_path(payload, field)) for field in anchor_group):
            return CandidateMapping(primitive_type=primitive_type, confidence="low", score=0, matched_fields=[])
    matched = [field for field in fields if _field_present(payload, field, specs)]
    score = int((len(matched) / len(fields)) * 100)
    confidence = "high" if score >= 80 else "medium" if score >= 50 else "low"
    return CandidateMapping(primitive_type=primitive_type, confidence=confidence, score=score, matched_fields=matched)


def _field_mappings(payload: dict[str, Any], primitive_type: str) -> list[FieldMapping]:
    specs = FIELD_SPECS.get(primitive_type, {})
    required = set(REQUIRED_FIELDS.get(primitive_type, []))
    mappings: list[FieldMapping] = []
    for canonical_field, keys in specs.items():
        source = _first_present_key(payload, keys)
        if source is None and canonical_field not in required:
            continue
        mappings.append(
            FieldMapping(
                source_field=source,
                canonical_field=canonical_field,
                source_path=source,
                canonical_path=canonical_field,
                confidence="high" if source else "low",
                required=canonical_field in required,
                matched=source is not None,
            )
        )
    return mappings


def _field_present(payload: dict[str, Any], field: str, aliases: dict[str, list[str]]) -> bool:
    keys = aliases.get(field, [field])
    return any(_present(_get_path(payload, key)) for key in keys)


def _first_present_key(payload: dict[str, Any], keys: Iterable[str]) -> str | None:
    for key in keys:
        if _present(_get_path(payload, key)):
            return key
    return None


def _source_records(payload: dict[str, Any]) -> list[SourceRecord]:
    records = _first(payload, "source_records", default=[]) or []
    return [record if isinstance(record, SourceRecord) else SourceRecord.model_validate(record) for record in records]


def _metadata(payload: dict[str, Any]) -> dict[str, Any]:
    metadata = dict(payload.get("metadata") or {})
    metadata.setdefault("native", payload)
    return metadata


def _first(payload: dict[str, Any], *keys: str, default: Any = ...):
    for key in keys:
        value = _get_path(payload, key)
        if _present(value):
            return value
    if default is not ...:
        return default
    return None


def _instrument(payload: dict[str, Any]) -> dict[str, Any] | None:
    instrument = _first(payload, "instrument", default=None)
    if isinstance(instrument, dict):
        return instrument
    for key in ("sensor", "device"):
        value = _first(payload, key, default=None)
        if isinstance(value, dict):
            return value
    identifier = _first(payload, "instrument_id", "sensor_id", "device_id", default=None)
    if identifier is not None:
        return {"id": identifier}
    return None


def _field_coverage(
    source_paths: list[str],
    field_mappings: list[FieldMapping],
    mapped_paths: set[str],
    ignored_paths: set[str],
    extension_preserved_paths: set[str],
) -> list[SourceFieldCoverage]:
    coverage: list[SourceFieldCoverage] = []
    for path in sorted(source_paths):
        canonical = _canonical_for_source_path(path, field_mappings)
        if path in mapped_paths:
            coverage.append(SourceFieldCoverage(source_field=path, status="canonical_mapped", canonical_field=canonical))
        elif path in ignored_paths:
            coverage.append(SourceFieldCoverage(source_field=path, status="explicitly_ignored"))
        elif path in extension_preserved_paths:
            coverage.append(SourceFieldCoverage(source_field=path, status="extension_preserved"))
        else:
            coverage.append(SourceFieldCoverage(source_field=path, status="silently_lost"))
    return coverage


def _canonical_for_source_path(path: str, field_mappings: list[FieldMapping]) -> str | None:
    for mapping in field_mappings:
        source = mapping.source_path or mapping.source_field
        if source and _path_covers(source, path):
            return mapping.canonical_path or mapping.canonical_field
    return None


def _source_field_paths(value: Any, prefix: str = "") -> list[str]:
    if isinstance(value, dict):
        if not value and prefix:
            return [prefix]
        paths: list[str] = []
        for key in sorted(value):
            child = f"{prefix}.{key}" if prefix else str(key)
            paths.extend(_source_field_paths(value[key], child))
        return paths
    if isinstance(value, list):
        if not value and prefix:
            return [prefix]
        paths = []
        for item in value:
            if isinstance(item, dict):
                paths.extend(_source_field_paths(item, f"{prefix}[]" if prefix else "[]"))
            else:
                paths.append(prefix)
        return sorted(set(paths))
    return [prefix] if prefix else []


def _special_path(path: str) -> bool:
    return any(path == field or path.startswith(f"{field}.") or path.startswith(f"{field}[]") for field in SPECIAL_NATIVE_FIELDS)


def _path_covers(pattern: str, path: str) -> bool:
    return path == pattern or path.startswith(f"{pattern}.") or path.startswith(f"{pattern}[]")


def _get_path(payload: dict[str, Any], path: str) -> Any:
    current: Any = payload
    for part in path.split("."):
        if not isinstance(current, dict) or part not in current:
            return None
        current = current[part]
    return current


def _present(value: Any) -> bool:
    if value is None:
        return False
    if isinstance(value, str):
        return bool(value)
    if isinstance(value, (list, dict)):
        return bool(value)
    return True

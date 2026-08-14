"""Additive evidence-operation primitives."""

from __future__ import annotations

import hashlib
from pathlib import Path
from typing import Any, Literal

from pydantic import Field

from .base import EvidencePrimitive
from .source_record import SourceRecord


class CalibrationRecord(EvidencePrimitive):
    """Instrument calibration evidence."""

    schema_id: Literal["athian.agevidence.calibration_record.v1"] = "athian.agevidence.calibration_record.v1"
    primitive_type: Literal["CalibrationRecord"] = "CalibrationRecord"
    instrument: str
    calibrated_at: str
    valid_until: str | None = None
    procedure: str | None = None
    standard: str | None = None
    certificate_hash: str | None = None
    source_records: list[SourceRecord] = Field(default_factory=list)
    metadata: dict[str, Any] = Field(default_factory=dict)
    limitations: list[str] = Field(default_factory=list)


class ProductLot(EvidencePrimitive):
    """Product or material lot evidence."""

    schema_id: Literal["athian.agevidence.product_lot.v1"] = "athian.agevidence.product_lot.v1"
    primitive_type: Literal["ProductLot"] = "ProductLot"
    product: str
    lot: str
    manufacturer: str | None = None
    manufactured_at: str | None = None
    expiry: str | None = None
    quantity: Any | None = None
    unit: str | None = None
    source_records: list[SourceRecord] = Field(default_factory=list)
    metadata: dict[str, Any] = Field(default_factory=dict)
    limitations: list[str] = Field(default_factory=list)


class AssetState(EvidencePrimitive):
    """Time-bound state for a device, paddock, herd, model, or facility."""

    schema_id: Literal["athian.agevidence.asset_state.v1"] = "athian.agevidence.asset_state.v1"
    primitive_type: Literal["AssetState"] = "AssetState"
    asset: str
    state: dict[str, Any]
    effective_at: str
    valid_until: str | None = None
    source_records: list[SourceRecord] = Field(default_factory=list)
    metadata: dict[str, Any] = Field(default_factory=dict)
    limitations: list[str] = Field(default_factory=list)


class Transformation(EvidencePrimitive):
    """Deterministic transformation metadata for derived evidence."""

    schema_id: Literal["athian.agevidence.transformation.v1"] = "athian.agevidence.transformation.v1"
    primitive_type: Literal["Transformation"] = "Transformation"
    name: str
    version: str
    implementation: str | None = None
    parameters: dict[str, Any] = Field(default_factory=dict)
    metadata: dict[str, Any] = Field(default_factory=dict)
    limitations: list[str] = Field(default_factory=list)


class DerivedObservation(EvidencePrimitive):
    """Observation derived from explicit inputs and a transformation."""

    schema_id: Literal["athian.agevidence.derived_observation.v1"] = "athian.agevidence.derived_observation.v1"
    primitive_type: Literal["DerivedObservation"] = "DerivedObservation"
    subject: str
    observable: str
    value: Any
    unit: str
    observed_at: str
    inputs: list[str | dict[str, Any]] = Field(default_factory=list)
    transformation: Transformation | dict[str, Any]
    derived_at: str | None = None
    source_records: list[SourceRecord] = Field(default_factory=list)
    metadata: dict[str, Any] = Field(default_factory=dict)
    limitations: list[str] = Field(default_factory=list)


class Attachment(EvidencePrimitive):
    """Local file attachment reference with deterministic metadata."""

    schema_id: Literal["athian.agevidence.attachment.v1"] = "athian.agevidence.attachment.v1"
    primitive_type: Literal["Attachment"] = "Attachment"
    path: str
    media_type: str
    sha256: str | None = None
    size: int | None = None
    name: str | None = None
    metadata: dict[str, Any] = Field(default_factory=dict)
    limitations: list[str] = Field(default_factory=list)

    @classmethod
    def from_path(cls, path: str | Path, media_type: str = "application/octet-stream") -> "Attachment":
        file_path = Path(path)
        data = file_path.read_bytes()
        return cls(
            path=str(file_path),
            name=file_path.name,
            media_type=media_type,
            size=len(data),
            sha256=f"sha256:{hashlib.sha256(data).hexdigest()}",
        )


class ExternalObject(EvidencePrimitive):
    """Reference to a large external object without copying the object locally."""

    schema_id: Literal["athian.agevidence.external_object.v1"] = "athian.agevidence.external_object.v1"
    primitive_type: Literal["ExternalObject"] = "ExternalObject"
    uri: str
    sha256: str
    size: int | None = None
    media_type: str | None = None
    name: str | None = None
    metadata: dict[str, Any] = Field(default_factory=dict)
    limitations: list[str] = Field(default_factory=list)

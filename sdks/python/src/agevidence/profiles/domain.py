"""Reusable domain evidence profiles.

Domain profiles sit above invariant primitives. They validate and describe what
the primitive means structurally without creating new protocol primitive types.
"""

from __future__ import annotations

from typing import Any, Literal

from pydantic import BaseModel, ConfigDict, Field

from agevidence.primitives import EvidencePrimitive


class DomainProfileMetadata(BaseModel):
    """Public metadata for a reusable domain profile."""

    model_config = ConfigDict(extra="forbid")

    profile_id: str
    name: str
    version: str
    family: str
    expected_primitive_type: str
    aliases: list[str] = Field(default_factory=list)
    input_requirements: list[str] = Field(default_factory=list)
    provenance_requirements: list[str] = Field(default_factory=list)
    limitations: list[str] = Field(default_factory=list)
    compatibility: dict[str, Any] = Field(default_factory=dict)


class DomainProfileApplication(BaseModel):
    """Result of applying a domain profile to one primitive."""

    model_config = ConfigDict(extra="forbid")

    profile_id: str
    profile_name: str
    profile_version: str
    primitive_type: str
    status: Literal["pass", "fail"]
    findings: list[str] = Field(default_factory=list)
    limitations: list[str] = Field(default_factory=list)
    primitive: dict[str, Any]


class DomainProfile:
    """Base contract for reusable evidence domain profiles."""

    metadata: DomainProfileMetadata

    def map(self, primitive: EvidencePrimitive | dict[str, Any]) -> DomainProfileApplication:
        """Apply this profile to a primitive.

        `map` is intentionally primitive-facing. Source adapters remain
        responsible for reading partner-native records.
        """

        payload = primitive.to_payload() if isinstance(primitive, EvidencePrimitive) else primitive
        primitive_type = str(payload.get("primitive_type") or payload.get("schema_id") or "Unknown")
        findings: list[str] = []
        if primitive_type != self.metadata.expected_primitive_type:
            findings.append(
                f"Expected {self.metadata.expected_primitive_type}, received {primitive_type}."
            )
        for requirement in self.metadata.input_requirements:
            if not _path_present(payload, requirement):
                findings.append(f"Missing profile requirement: {requirement}.")
        return DomainProfileApplication(
            profile_id=self.metadata.profile_id,
            profile_name=self.metadata.name,
            profile_version=self.metadata.version,
            primitive_type=primitive_type,
            status="fail" if findings else "pass",
            findings=findings,
            limitations=list(self.metadata.limitations),
            primitive=payload,
        )


def _path_present(payload: dict[str, Any], path: str) -> bool:
    current: Any = payload
    for part in path.split("."):
        if not isinstance(current, dict) or part not in current:
            return False
        current = current[part]
    if current is None or current == "" or current == [] or current == {}:
        return False
    return True


def _profile(
    *,
    profile_id: str,
    name: str,
    family: str,
    expected_primitive_type: str,
    aliases: list[str],
    input_requirements: list[str],
    provenance_requirements: list[str],
    limitations: list[str],
) -> DomainProfileMetadata:
    return DomainProfileMetadata(
        profile_id=profile_id,
        name=name,
        version="v1",
        family=family,
        expected_primitive_type=expected_primitive_type,
        aliases=aliases,
        input_requirements=input_requirements,
        provenance_requirements=provenance_requirements,
        limitations=limitations,
        compatibility={"core_primitive_contract": "v1", "schema_extension_required": False},
    )


class WaterDosingIntervention(DomainProfile):
    metadata = _profile(
        profile_id="au.livestock.water-dosing.v1",
        name="WaterDosingIntervention",
        family="intervention_delivery",
        expected_primitive_type="InterventionEvent",
        aliases=["water-dosing", "dit.water_dosing_intervention"],
        input_requirements=[
            "target",
            "intervention",
            "quantity",
            "unit",
            "occurred_at",
            "metadata.water_volume",
            "metadata.dosing_rate",
            "metadata.device_id",
            "metadata.installation_id",
        ],
        provenance_requirements=["source_records", "batch"],
        limitations=["Delivered volume is not automatically mixed, administered, or consumed."],
    )


class FeedAdditiveDelivery(DomainProfile):
    metadata = _profile(
        profile_id="au.livestock.feed-additive-delivery.v1",
        name="FeedAdditiveDelivery",
        family="intervention_delivery",
        expected_primitive_type="InterventionEvent",
        aliases=["feed-additive-delivery", "rumin8.feed_additive_delivery_manifest"],
        input_requirements=[
            "target",
            "intervention",
            "quantity",
            "unit",
            "occurred_at",
            "batch",
            "metadata.product_lot_id",
            "metadata.custody_state",
        ],
        provenance_requirements=["source_records", "batch"],
        limitations=["Delivered is kept separate from mixed, administered, and consumed."],
    )


class BioactiveProductLot(DomainProfile):
    metadata = _profile(
        profile_id="au.livestock.bioactive-product-lot.v1",
        name="BioactiveProductLot",
        family="product_lot",
        expected_primitive_type="InterventionEvent",
        aliases=["bioactive-product-lot", "sea_forest.bioactive_product_lot_manifest"],
        input_requirements=[
            "target",
            "intervention",
            "quantity",
            "unit",
            "occurred_at",
            "batch",
            "metadata.product_lot_id",
            "metadata.active_compound",
            "metadata.concentration",
        ],
        provenance_requirements=["source_records", "batch"],
        limitations=["Product lot evidence does not prove administration or animal consumption."],
    )


class PrecisionChemicalApplication(DomainProfile):
    metadata = _profile(
        profile_id="au.cropping.precision-chemical-application.v1",
        name="PrecisionChemicalApplication",
        family="operational_event",
        expected_primitive_type="OperationalEvent",
        aliases=["precision-chemical-application", "swarmfarm.precision_chemical_application"],
        input_requirements=[
            "machine",
            "operation",
            "started_at",
            "completed_at",
            "location",
            "metadata.application_product",
            "metadata.application_rate",
            "metadata.nozzle_pressure",
            "metadata.machine_speed",
        ],
        provenance_requirements=["source_records"],
        limitations=["Operational evidence does not establish chemical compliance or yield outcome."],
    )


class ObjectiveCarcassMeasurement(DomainProfile):
    metadata = _profile(
        profile_id="au.livestock.objective-carcass-measurement.v1",
        name="ObjectiveCarcassMeasurement",
        family="instrument_observation",
        expected_primitive_type="Observation",
        aliases=["objective-carcass-measurement", "meq.objective_carcass_measurement"],
        input_requirements=[
            "subject",
            "observable",
            "value",
            "unit",
            "observed_at",
            "instrument.id",
            "instrument.calibration_reference",
            "metadata.raw_artifact_digest",
        ],
        provenance_requirements=["source_records", "instrument.calibration_reference"],
        limitations=["Model-derived carcass traits require explicit ModelRun lineage."],
    )


class EntericMethaneMeasurement(DomainProfile):
    metadata = _profile(
        profile_id="au.livestock.enteric-methane-measurement.v1",
        name="EntericMethaneMeasurement",
        family="instrument_observation",
        expected_primitive_type="Observation",
        aliases=["enteric-methane-measurement", "agscent.enteric_methane_measurement"],
        input_requirements=[
            "subject",
            "observable",
            "value",
            "unit",
            "observed_at",
            "instrument.id",
            "instrument.calibration_reference",
            "metadata.raw_frame_commitment",
        ],
        provenance_requirements=["source_records", "instrument.calibration_reference"],
        limitations=["PPM concentration is not methane flux unless a downstream model derives flux."],
    )


class SpatialBiomassObservation(DomainProfile):
    metadata = _profile(
        profile_id="au.spatial.biomass-observation.v1",
        name="SpatialBiomassObservation",
        family="spatial_observation",
        expected_primitive_type="SpatialObservation",
        aliases=["spatial-biomass-observation", "cibo.spatial_biomass_observation"],
        input_requirements=[
            "geometry",
            "observable",
            "value",
            "unit",
            "observed_at",
            "crs",
            "metadata.observation_window",
            "metadata.imagery_source",
        ],
        provenance_requirements=["source_records"],
        limitations=["Large imagery remains external and is represented by digest/reference metadata."],
    )


class SpatialDigitalTwinManifest(DomainProfile):
    metadata = _profile(
        profile_id="au.spatial.digital-twin-manifest.v1",
        name="SpatialDigitalTwinManifest",
        family="large_asset_manifest",
        expected_primitive_type="SourceRecord",
        aliases=["spatial-digital-twin-manifest", "agronomeye.spatial_digital_twin_manifest"],
        input_requirements=[
            "source_system",
            "record_id",
            "observed_at",
            "controlled_uri",
            "commitment",
            "metadata.root_commitment",
            "metadata.crs",
            "metadata.chunk_manifest",
        ],
        provenance_requirements=["commitment"],
        limitations=["The bundle commits to large assets; it does not warehouse point clouds."],
    )

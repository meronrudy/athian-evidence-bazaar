"""Synthetic Wave 1/2 source adapters.

These adapters intentionally map partner-shaped synthetic records into existing
canonical primitives. They are proof kits, not partner certifications.
"""

from __future__ import annotations

from typing import Any

from agevidence.adapters import Adapter
from agevidence.primitives import InterventionEvent, Observation, OperationalEvent, SourceRecord, SpatialObservation


class _WaveAdapter(Adapter):
    source_system: str

    def _required(self, record: dict[str, Any], field: str) -> Any:
        value = record.get(field)
        if value is None or value == "" or value == [] or value == {}:
            raise ValueError(f"{field} is required")
        return value

    def _number(self, record: dict[str, Any], field: str) -> int | float:
        value = self._required(record, field)
        if not isinstance(value, (int, float)):
            raise ValueError(f"{field} must be numeric")
        return value

    def _source_record(self, record: dict[str, Any], *, record_id: str, observed_at: str, commitment: str) -> SourceRecord:
        return SourceRecord(
            source_system=self.source_system,
            record_id=str(self._required(record, record_id)),
            observed_at=str(self._required(record, observed_at)),
            commitment=str(self._required(record, commitment)),
        )

    def _crs(self, record: dict[str, Any]) -> str:
        crs = str(self._required(record, "crs"))
        if not crs.startswith("EPSG:"):
            raise ValueError("crs must use an EPSG code")
        return crs

    def _geometry(self, record: dict[str, Any]) -> dict[str, Any]:
        geometry = record.get("geometry")
        if geometry is None or geometry == "":
            raise ValueError("geometry is required")
        if not isinstance(geometry, dict) or not geometry.get("type") or not geometry.get("coordinates"):
            raise ValueError("geometry must be valid GeoJSON")
        return geometry


class DITHubWaterDosingAdapter(_WaveAdapter):
    source_system = "dit-uhub-webhook"

    def map(self, record: dict[str, Any]) -> InterventionEvent:
        return InterventionEvent(
            target=str(self._required(record, "water_line_id")),
            intervention="methane_supplement_delivery",
            quantity=self._number(record, "delivered_litres"),
            unit=str(self._required(record, "unit")),
            occurred_at=str(self._required(record, "timestamp")),
            batch=str(self._required(record, "supplement_batch_id")),
            source_records=[
                self._source_record(
                    record,
                    record_id="webhook_id",
                    observed_at="timestamp",
                    commitment="source_commitment",
                )
            ],
            metadata={
                "domain_profile": "WaterDosingIntervention",
                "profile_id": "au.livestock.water-dosing.v1",
                "native_source": "uHUB AWS IoT webhook",
                "water_volume": record.get("delivered_litres"),
                "dosing_rate": record.get("pump_rate_l_min"),
                "device_id": record.get("device_id") or record.get("water_line_id"),
                "installation_id": record.get("installation_id") or record.get("water_point_id"),
                "water_point_id": record.get("water_point_id"),
                "pulse_count": record.get("pulse_count"),
                "pump_rate_l_min": record.get("pump_rate_l_min"),
                "tank_conductivity_us_cm": record.get("tank_conductivity_us_cm"),
            },
        )


class MEQObjectiveCarcassAdapter(_WaveAdapter):
    source_system = "meq-spectral-export"

    def map(self, record: dict[str, Any]) -> Observation:
        return Observation(
            subject=str(self._required(record, "carcass_id")),
            observable="intramuscular_fat_percent",
            value=self._number(record, "intramuscular_fat_percent"),
            unit=str(self._required(record, "unit")),
            observed_at=str(self._required(record, "timestamp")),
            instrument={
                "id": str(self._required(record, "instrument_id")),
                "calibration_reference": str(self._required(record, "calibration_reference")),
            },
            method="hyperspectral_needle_reflectance",
            source_records=[
                self._source_record(
                    record,
                    record_id="spectral_file_id",
                    observed_at="timestamp",
                    commitment="spectral_digest",
                )
            ],
            metadata={
                "domain_profile": "ObjectiveCarcassMeasurement",
                "profile_id": "au.livestock.objective-carcass-measurement.v1",
                "raw_artifact_digest": record.get("spectral_digest"),
                "carcass_yield_percent": record.get("carcass_yield_percent"),
                "grading_tag": record.get("grading_tag"),
                "plant_id": record.get("plant_id"),
            },
        )


class AgscentEntericMethaneAdapter(_WaveAdapter):
    source_system = "agscent-uart-stream"

    def map(self, record: dict[str, Any]) -> Observation:
        return Observation(
            subject=str(self._required(record, "animal_id")),
            observable="methane_concentration",
            value=self._number(record, "methane_ppm"),
            unit=str(self._required(record, "unit")),
            observed_at=str(self._required(record, "timestamp")),
            instrument={
                "id": str(self._required(record, "sensor_id")),
                "calibration_reference": str(self._required(record, "calibration_reference")),
            },
            method="breath_voc_sensor_array",
            source_records=[
                self._source_record(
                    record,
                    record_id="breath_session_id",
                    observed_at="timestamp",
                    commitment="source_commitment",
                )
            ],
            metadata={
                "domain_profile": "EntericMethaneMeasurement",
                "profile_id": "au.livestock.enteric-methane-measurement.v1",
                "raw_frame_commitment": record.get("source_commitment"),
                "raw_uart_hex": record.get("raw_uart_hex"),
                "voc_channels": record.get("voc_channels"),
            },
        )


class CiboSpatialBiomassAdapter(_WaveAdapter):
    source_system = "cibo-spatial-api"

    def map(self, record: dict[str, Any]) -> list[SpatialObservation]:
        observed_at = str(self._required(record, "observed_at"))
        crs = self._crs(record)
        geometry = self._geometry(record)
        source_records = [
            self._source_record(
                record,
                record_id="request_id",
                observed_at="observed_at",
                commitment="source_commitment",
            )
        ]
        common_metadata = {
            "domain_profile": "SpatialBiomassObservation",
            "profile_id": "au.spatial.biomass-observation.v1",
            "model_id": record.get("model_id"),
            "scene_ids": record.get("scene_ids"),
            "observation_window": record.get("observation_window") or {"observed_at": observed_at},
            "imagery_source": record.get("scene_ids"),
        }
        return [
            SpatialObservation(
                subject=record.get("paddock_id"),
                geometry=geometry,
                observable="pasture_biomass_foo",
                value=self._number(record, "pasture_biomass_foo_kg_dm_ha"),
                unit="kg_dm_ha",
                observed_at=observed_at,
                crs=crs,
                source_records=source_records,
                metadata=common_metadata,
            ),
            SpatialObservation(
                subject=record.get("paddock_id"),
                geometry=geometry,
                observable="fractional_cover",
                value=self._number(record, "fractional_cover"),
                unit="ratio",
                observed_at=observed_at,
                crs=crs,
                source_records=source_records,
                metadata=common_metadata,
            ),
        ]


class AgronomeyeDigitalTwinAdapter(_WaveAdapter):
    source_system = "agronomeye-digital-twin-export"

    def map(self, record: dict[str, Any]) -> SourceRecord:
        return SourceRecord(
            source_system=self.source_system,
            record_id=str(self._required(record, "scan_id")),
            observed_at=str(self._required(record, "observed_at")),
            controlled_uri=str(self._required(record, "point_cloud_uri")),
            commitment=str(self._required(record, "point_cloud_root_hash")),
            metadata={
                "domain_profile": "SpatialDigitalTwinManifest",
                "profile_id": "au.spatial.digital-twin-manifest.v1",
                "root_commitment": record.get("point_cloud_root_hash"),
                "chunk_manifest": record.get("chunk_manifest") or [{"sequence": 1, "digest": record.get("point_cloud_root_hash")}],
                "property_id": record.get("property_id"),
                "point_count": record.get("point_count"),
                "crs": self._crs(record),
                "sensors": record.get("sensors"),
                "geometry": record.get("bounding_polygon"),
            },
        )


class Rumin8FeedAdditiveAdapter(_WaveAdapter):
    source_system = "rumin8-delivery-receipt"

    def map(self, record: dict[str, Any]) -> InterventionEvent:
        return InterventionEvent(
            target=str(self._required(record, "herd_id")),
            intervention="synthesized_tribromomethane_delivery",
            quantity=self._number(record, "quantity_kg"),
            unit=str(self._required(record, "unit")),
            occurred_at=str(self._required(record, "delivered_at")),
            batch=str(self._required(record, "lot_id")),
            source_records=[
                self._source_record(
                    record,
                    record_id="delivery_receipt_id",
                    observed_at="delivered_at",
                    commitment="source_commitment",
                )
            ],
            metadata={
                "domain_profile": "FeedAdditiveDelivery",
                "profile_id": "au.livestock.feed-additive-delivery.v1",
                "product_lot_id": record.get("lot_id"),
                "custody_state": "delivered",
                "feed_mill_id": record.get("feed_mill_id"),
                "formulation_spec_id": record.get("formulation_spec_id"),
                "product_id": record.get("product_id"),
                "inclusion_rate_g_head_day": record.get("inclusion_rate_g_head_day"),
            },
        )


class SeaForestBioactiveLotAdapter(_WaveAdapter):
    source_system = "sea-forest-batch-csv"

    def map(self, record: dict[str, Any]) -> InterventionEvent:
        return InterventionEvent(
            target=str(self._required(record, "herd_id")),
            intervention="asparagopsis_bioactive_supplementation",
            quantity=self._number(record, "quantity_kg"),
            unit=str(self._required(record, "unit")),
            occurred_at=str(self._required(record, "mixed_at")),
            batch=str(self._required(record, "product_lot_id")),
            source_records=[
                self._source_record(
                    record,
                    record_id="batch_csv_row_id",
                    observed_at="mixed_at",
                    commitment="source_commitment",
                )
            ],
            metadata={
                "domain_profile": "BioactiveProductLot",
                "profile_id": "au.livestock.bioactive-product-lot.v1",
                "product_lot_id": record.get("product_lot_id"),
                "active_compound": "asparagopsis_oil_extract",
                "concentration": record.get("asparagopsis_oil_concentration_mg_g"),
                "manufacturer_batch_id": record.get("manufacturer_batch_id"),
                "asparagopsis_oil_concentration_mg_g": record.get("asparagopsis_oil_concentration_mg_g"),
            },
        )


class SwarmFarmPrecisionChemicalAdapter(_WaveAdapter):
    source_system = "swarmconnect-spray-webhook"

    def map(self, record: dict[str, Any]) -> OperationalEvent:
        machine = str(self._required(record, "robot_id"))
        if not machine.startswith("machine:"):
            raise ValueError("robot_id must be a machine identifier")
        return OperationalEvent(
            machine=machine,
            operation="precision_chemical_application",
            started_at=str(self._required(record, "started_at")),
            completed_at=str(self._required(record, "completed_at")),
            location=self._geometry(record),
            source_records=[
                self._source_record(
                    record,
                    record_id="event_id",
                    observed_at="started_at",
                    commitment="source_commitment",
                )
            ],
            metadata={
                "domain_profile": "PrecisionChemicalApplication",
                "profile_id": "au.cropping.precision-chemical-application.v1",
                "application_product": record.get("chemical_product"),
                "application_rate": record.get("application_rate_l_ha"),
                "nozzle_pressure": record.get("nozzle_pressure_kpa"),
                "machine_speed": record.get("speed_m_s"),
                "nozzle_pressure_kpa": record.get("nozzle_pressure_kpa"),
                "speed_m_s": record.get("speed_m_s"),
                "chemical_product": record.get("chemical_product"),
                "application_rate_l_ha": record.get("application_rate_l_ha"),
            },
        )

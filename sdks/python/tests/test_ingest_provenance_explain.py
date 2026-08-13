from __future__ import annotations

from agevidence import ingest
from agevidence.explain import explain
from agevidence.primitives import Observation
from agevidence.provenance import check


def test_ingest_maps_native_observation_deterministically():
    result = ingest(
        {
            "animal_id": "animal:1",
            "observable": "liveweight",
            "value": 481.4,
            "unit": "kg",
            "observed_at": "2026-08-12T00:00:00Z",
        }
    )

    assert result.primitive_type == "Observation"
    assert result.confidence in {"high", "medium"}
    assert result.committed is False
    assert result.primitive["subject"] == "animal:1"


def test_ingest_prefers_spatial_observation_when_geometry_present():
    result = ingest(
        {
            "geometry": {"type": "Point", "coordinates": [151.2, -33.8]},
            "observable": "feed_on_offer",
            "value": 1840,
            "unit": "kg_dm_ha",
            "observed_at": "2026-08-12T00:00:00Z",
        }
    )

    assert result.primitive_type == "SpatialObservation"


def test_provenance_distinguishes_local_checks_from_external_states():
    report = check(Observation(subject="animal:1", observable="liveweight", value=1, unit="kg", observed_at="2026-08-12T00:00:00Z"))

    assert report.structural_validity == "pass"
    assert report.provenance_completeness == "partial"
    assert report.program_eligibility == "not_evaluated"
    assert report.verification_status == "not_issued"
    assert report.institutional_reliance == "not_asserted"


def test_explain_reports_calibration_remediation_without_certification_claims():
    report = explain(
        {
            "subject": "animal:1",
            "observable": "enteric_methane",
            "value": 18.2,
            "unit": "g_ch4_min",
            "observed_at": "2026-08-12T00:00:00Z",
            "instrument": {"id": "breath-sensor:1"},
        }
    )

    assert report.primitive_type == "Observation"
    assert "CALIBRATION_REFERENCE_MISSING" in report.missing
    assert "carbon-credit eligibility" in report.does_not_establish

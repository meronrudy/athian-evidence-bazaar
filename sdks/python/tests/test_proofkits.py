from __future__ import annotations

import json
import subprocess
import tempfile
from importlib import resources
from pathlib import Path

import pytest
from typer.testing import CliRunner

from agevidence.adapters import load_source_adapter
from agevidence.cli import app
from agevidence.ingest import ingest
from agevidence.primitives import local_digest
from agevidence.profiles import get_domain_profile, list_domain_profiles
from agevidence.proofkits import list_proofkits, load_expected_output, load_native_fixture, run_proofkit
from agevidence.proofkits import registry as proof_registry


REPO_ROOT = Path(__file__).resolve().parents[3]
RUNNER = CliRunner()
EXPECTED_IDS = {
    "dit.water_dosing_intervention",
    "meq.objective_carcass_measurement",
    "agscent.enteric_methane_measurement",
    "cibo.spatial_biomass_observation",
    "agronomeye.spatial_digital_twin_manifest",
    "rumin8.feed_additive_delivery_manifest",
    "sea_forest.bioactive_product_lot_manifest",
    "swarmfarm.precision_chemical_application",
}
SCHEMA_BY_PRIMITIVE = {
    "SourceRecord": "source_record",
    "Observation": "observation",
    "SpatialObservation": "spatial_observation",
    "InterventionEvent": "intervention_event",
    "OperationalEvent": "operational_event",
}


def test_proofkit_registry_loads_supplied_wave_matrix_only():
    proofkits = list_proofkits()
    ids = {proofkit.id for proofkit in proofkits}

    assert ids == EXPECTED_IDS
    assert len(ids) == len(proofkits)
    assert all(proofkit.generated_primitive in SCHEMA_BY_PRIMITIVE for proofkit in proofkits)
    assert all(proofkit.profile_id for proofkit in proofkits)
    assert all(proofkit.domain_profile for proofkit in proofkits)
    assert "ProAgni" not in {proofkit.company for proofkit in proofkits}


def test_duplicate_proofkit_ids_are_rejected(monkeypatch):
    first = list_proofkits()[0].model_dump(mode="json")

    def fake_read_json(relative: str):
        if relative == "metadata.json":
            return {"proofkits": [first, first]}
        raise AssertionError(relative)

    monkeypatch.setattr(proof_registry, "_read_json", fake_read_json)

    with pytest.raises(ValueError, match="Duplicate proof kit ids"):
        proof_registry.list_proofkits()


def test_packaged_proofkit_resources_are_available():
    package_root = resources.files("agevidence.proofkits")

    for proofkit in list_proofkits():
        assert package_root.joinpath(proofkit.fixture).is_file()
        assert package_root.joinpath(proofkit.expected).is_file()
        assert package_root.joinpath(proofkit.readme).is_file()
        assert load_native_fixture(proofkit.id)
        assert load_expected_output(proofkit.id)["proof_id"] == proofkit.id


def test_proofkits_match_golden_outputs_and_digests():
    for proofkit in list_proofkits():
        result = run_proofkit(proofkit.id)
        expected = load_expected_output(proofkit.id)

        assert result.adapter_report["passed"] is True
        assert result.adapter_report["canonical_schema_extensions_required"] is False
        assert result.primitives == expected["primitives"]
        assert [item["status"] for item in result.profile_applications] == ["pass"] * len(result.primitives)
        assert {item["profile_id"] for item in result.profile_applications} == {proofkit.profile_id}
        assert result.local_digests == [local_digest(primitive) for primitive in expected["primitives"]]
        assert result.production_signed is False
        assert "regulatory eligibility" in result.authority_boundary


def test_proofkit_cli_list_run_and_write(tmp_path):
    listed = RUNNER.invoke(app, ["proof", "list"])
    assert listed.exit_code == 0
    assert "dit.water_dosing_intervention" in listed.stdout
    assert "swarmfarm.precision_chemical_application" in listed.stdout

    run = RUNNER.invoke(app, ["proof", "run", "cibo.spatial_biomass_observation", "--format", "json"])
    assert run.exit_code == 0
    assert '"domain_profile": "SpatialBiomassObservation"' in run.stdout
    assert '"observable": "fractional_cover"' in run.stdout

    profiles = RUNNER.invoke(app, ["profile", "list"])
    assert profiles.exit_code == 0
    assert "au.livestock.water-dosing.v1" in profiles.stdout

    inspected = RUNNER.invoke(app, ["profile", "inspect", "dit.water_dosing_intervention", "--format", "json"])
    assert inspected.exit_code == 0
    assert '"profile_id": "au.livestock.water-dosing.v1"' in inspected.stdout

    out = tmp_path / "proof"
    written = RUNNER.invoke(app, ["proof", "write", "sea_forest.bioactive_product_lot_manifest", "--out", str(out)])
    assert written.exit_code == 0
    assert (out / "manifest.json").exists()
    assert (out / "native.json").exists()
    assert (out / "expected.json").exists()
    assert (out / "README.md").exists()
    assert (out / "adapter.py").exists()

    adapter_test = RUNNER.invoke(app, ["adapter", "test", str(out / "adapter.py"), str(out / "native.json"), "--format", "json"])
    assert adapter_test.exit_code == 0
    assert '"mapped_count": 1' in adapter_test.stdout


def test_domain_profile_registry_and_ingest_application():
    profiles = {profile.metadata.profile_id: profile for profile in list_domain_profiles()}

    assert set(profiles) == {
        "au.livestock.water-dosing.v1",
        "au.livestock.feed-additive-delivery.v1",
        "au.livestock.bioactive-product-lot.v1",
        "au.cropping.precision-chemical-application.v1",
        "au.livestock.objective-carcass-measurement.v1",
        "au.livestock.enteric-methane-measurement.v1",
        "au.spatial.biomass-observation.v1",
        "au.spatial.digital-twin-manifest.v1",
    }
    assert get_domain_profile("dit.water_dosing_intervention").metadata.profile_id == "au.livestock.water-dosing.v1"

    primitive = load_expected_output("dit.water_dosing_intervention")["primitives"][0]
    result = ingest(primitive, primitive="InterventionEvent", profile="au.livestock.water-dosing.v1")

    assert result.profile_application is not None
    assert result.profile_application["status"] == "pass"
    assert result.profile_application["profile_id"] == "au.livestock.water-dosing.v1"


@pytest.mark.parametrize(
    ("proof_id", "field", "value", "message"),
    [
        ("dit.water_dosing_intervention", "timestamp", None, "timestamp is required"),
        ("meq.objective_carcass_measurement", "unit", None, "unit is required"),
        ("cibo.spatial_biomass_observation", "geometry", {}, "geometry must be valid GeoJSON"),
        ("agronomeye.spatial_digital_twin_manifest", "crs", "GDA2020", "crs must use an EPSG code"),
        ("rumin8.feed_additive_delivery_manifest", "lot_id", None, "lot_id is required"),
        ("sea_forest.bioactive_product_lot_manifest", "product_lot_id", None, "product_lot_id is required"),
        ("swarmfarm.precision_chemical_application", "robot_id", "swarmfarm-001", "robot_id must be a machine identifier"),
    ],
)
def test_proofkit_adversarial_native_payloads_fail_fast(proof_id, field, value, message):
    proofkit = proof_registry.get_proofkit(proof_id)
    record = load_native_fixture(proof_id)
    record[field] = value
    adapter = load_source_adapter(proofkit.adapter)

    with pytest.raises(ValueError, match=message):
        adapter.map(record)


def test_proofkit_primitives_pass_rust_schema_validation():
    for proofkit in list_proofkits():
        result = run_proofkit(proofkit.id)
        for primitive in result.primitives:
            assert _rust_validate(primitive)


def _rust_validate(payload: dict) -> bool:
    schema = SCHEMA_BY_PRIMITIVE[payload["primitive_type"]]
    with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False) as file:
        json.dump(payload, file)
        path = Path(file.name)
    try:
        completed = subprocess.run(
            ["cargo", "run", "--quiet", "-p", "baink-cli", "--", "agevidence", "validate", "--schema", schema, str(path)],
            cwd=REPO_ROOT,
            capture_output=True,
            text=True,
            check=False,
        )
    finally:
        path.unlink(missing_ok=True)
    return completed.returncode == 0

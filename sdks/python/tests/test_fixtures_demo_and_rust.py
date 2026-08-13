from __future__ import annotations

from pathlib import Path

from typer.testing import CliRunner

import agevidence
from agevidence.cli import app
from agevidence.doctor import doctor
from agevidence.demo import run_demo
from agevidence.fixtures import fixture_names, load_fixture
from agevidence.ingest import ingest
from agevidence.testing import assert_evidence_valid, assert_provenance_complete, assert_rust_conformant


runner = CliRunner()


def rust_command() -> str:
    return "cargo run --quiet -p baink-cli --"


def test_fixture_loader_and_assertion_helpers():
    assert "livestock-weight" in fixture_names()
    assert "machine-operation" in fixture_names()
    fixture = load_fixture("livestock-weight")
    result = ingest(fixture.payload, primitive=fixture.primitive_type)

    assert_evidence_valid(result.primitive)
    assert_provenance_complete(result.primitive)


def test_rust_accepts_observation_fixture():
    fixture = load_fixture("livestock-weight")
    result = ingest(fixture.payload, primitive=fixture.primitive_type)

    assert_rust_conformant(result.primitive, schema="observation", command=rust_command())


def test_demo_is_local_and_machine_readable():
    result = run_demo("livestock-weight")

    assert result.no_account_used
    assert result.no_api_key_used
    assert result.no_network_request_used
    assert result.primitive_type == "Observation"
    assert agevidence.demo().primitive_type == "Observation"


def test_doctor_passes_without_rails_or_api_token(monkeypatch):
    monkeypatch.delenv("AGEVIDENCE_BASE_URL", raising=False)
    monkeypatch.delenv("AGEVIDENCE_API_TOKEN", raising=False)

    report = doctor()

    assert report.ready
    assert any(check.name == "Rails API" and check.status == "not_configured" for check in report.checks)
    assert any(check.name == "API token" and check.status == "not_configured" for check in report.checks)


def test_cli_local_commands(tmp_path):
    fixture_path = tmp_path / "weight.json"
    fixture_result = runner.invoke(app, ["fixture", "write", "livestock-weight", "--out", str(fixture_path)])
    assert fixture_result.exit_code == 0
    assert fixture_path.exists()

    ingest_result = runner.invoke(app, ["ingest", str(fixture_path)])
    assert ingest_result.exit_code == 0
    assert '"primitive_type": "Observation"' in ingest_result.stdout

    explain_result = runner.invoke(app, ["explain", str(fixture_path)])
    assert explain_result.exit_code == 0
    assert "does_not_establish" in explain_result.stdout


def test_cli_verify_delegates_to_baink_cli_contract():
    repo_root = Path(__file__).resolve().parents[3]
    result = runner.invoke(
        app,
        [
            "verify",
            str(repo_root / "sdks/python/tests/fixtures/golden/demo_bundle.json"),
        ],
        env={"AGEVIDENCE_VERIFIER_COMMAND": rust_command()},
    )

    assert result.exit_code == 0
    assert "Verification PASS" in result.stdout


def test_cli_doctor_returns_ready_for_local_development():
    result = runner.invoke(app, ["doctor"], env={"AGEVIDENCE_VERIFIER_COMMAND": rust_command()})

    assert result.exit_code == 0
    assert "READY FOR LOCAL DEVELOPMENT" in result.stdout

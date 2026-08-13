from __future__ import annotations

import json

from typer.testing import CliRunner

from agevidence.adapters import Adapter, load_source_adapter, test_source_adapter as run_source_adapter_test
from agevidence.cli import app


runner = CliRunner()


def write_source_adapter(path):
    path.write_text(
        """from agevidence.adapters import Adapter
from agevidence.primitives import Observation


class MethaneAdapter(Adapter):
    def map(self, record):
        return Observation(
            subject=f"animal:{record['eid']}",
            observable="methane_concentration",
            value=record["ppm"],
            unit="ppm",
            observed_at=record["timestamp"],
            instrument={"id": record["sensor_id"]},
        )
""",
        encoding="utf-8",
    )


def write_fixture(path, *, eid="A-1"):
    path.write_text(
        json.dumps(
            {
                "eid": eid,
                "ppm": 18.7,
                "timestamp": "2026-08-12T14:05:11Z",
                "sensor_id": "SENSOR-17",
            }
        ),
        encoding="utf-8",
    )


def test_source_adapter_loads_path_without_object_when_single_subclass(tmp_path):
    adapter_path = tmp_path / "my_adapter.py"
    write_source_adapter(adapter_path)

    adapter = load_source_adapter(str(adapter_path))

    assert isinstance(adapter, Adapter)
    assert adapter.map({"eid": "A-1", "ppm": 18.7, "timestamp": "2026-08-12T00:00:00Z", "sensor_id": "S-1"}).primitive_type == "Observation"


def test_source_adapter_report_counts_incomplete_provenance_without_claiming_verification(tmp_path):
    adapter_path = tmp_path / "my_adapter.py"
    fixtures = tmp_path / "fixtures"
    fixtures.mkdir()
    write_source_adapter(adapter_path)
    write_fixture(fixtures / "one.json", eid="A-1")
    write_fixture(fixtures / "two.json", eid="A-2")

    report = run_source_adapter_test(f"{adapter_path}:MethaneAdapter", fixtures)

    assert report.fixture_count == 2
    assert report.mapped_count == 2
    assert report.structurally_valid == 2
    assert report.provenance_incomplete == 2
    assert not report.canonical_schema_extensions_required
    assert not report.failures
    assert "external verification" in report.authority_boundary
    assert "carbon-credit issuance" in report.authority_boundary


def test_source_adapter_cli_table_succeeds_for_canonical_mapping(tmp_path):
    adapter_path = tmp_path / "my_adapter.py"
    fixtures = tmp_path / "fixtures"
    fixtures.mkdir()
    write_source_adapter(adapter_path)
    write_fixture(fixtures / "one.json")

    result = runner.invoke(app, ["adapter", "test", str(adapter_path), str(fixtures), "--format", "table"])

    assert result.exit_code == 0
    assert "Agevidence Source Adapter Test" in result.stdout
    assert "No canonical schema extensions required." in result.stdout
    assert "verification" in result.stdout


def test_source_adapter_cli_fails_for_schema_extension(tmp_path):
    adapter_path = tmp_path / "custom_adapter.py"
    fixture = tmp_path / "record.json"
    adapter_path.write_text(
        """from agevidence.adapters import Adapter


class CustomAdapter(Adapter):
    def map(self, record):
        return {"primitive_type": "CustomEvidence", "value": record["value"]}
""",
        encoding="utf-8",
    )
    fixture.write_text('{"value": 1}', encoding="utf-8")

    result = runner.invoke(app, ["adapter", "test", f"{adapter_path}:CustomAdapter", str(fixture), "--format", "json"])

    assert result.exit_code == 1
    assert '"canonical_schema_extensions_required": true' in result.stdout


def test_ingest_and_explain_table_outputs(tmp_path):
    record = tmp_path / "weight.json"
    record.write_text(
        json.dumps(
            {
                "animal_id": "animal:1",
                "observable": "liveweight",
                "value": 481.4,
                "unit": "kg",
                "observed_at": "2026-08-12T14:05:11Z",
            }
        ),
        encoding="utf-8",
    )

    ingest = runner.invoke(app, ["ingest", str(record), "--format", "table"])
    explain = runner.invoke(app, ["explain", str(record), "--format", "table"])

    assert ingest.exit_code == 0
    assert "Candidate primitive: Observation" in ingest.stdout
    assert "Local provenance checks do not establish" in ingest.stdout
    assert explain.exit_code == 0
    assert "Agevidence Explain" in explain.stdout
    assert "Does not establish:" in explain.stdout


def test_adapter_can_return_sequence_of_primitives(tmp_path):
    adapter_path = tmp_path / "multi_adapter.py"
    fixture = tmp_path / "record.json"
    adapter_path.write_text(
        """from agevidence.adapters import Adapter
from agevidence.primitives import Observation


class MultiAdapter(Adapter):
    def map(self, record):
        return [
            Observation(subject="animal:1", observable="liveweight", value=1, unit="kg", observed_at=record["timestamp"]),
            Observation(subject="animal:2", observable="liveweight", value=2, unit="kg", observed_at=record["timestamp"]),
        ]
""",
        encoding="utf-8",
    )
    fixture.write_text('{"timestamp": "2026-08-12T14:05:11Z"}', encoding="utf-8")

    report = run_source_adapter_test(f"{adapter_path}:MultiAdapter", fixture)

    assert report.mapped_count == 2
    assert report.structurally_valid == 1

from __future__ import annotations

import json
import asyncio
from pathlib import Path

import pytest
from typer.testing import CliRunner

import agevidence
from agevidence.adapters import adapter_coverage, compare_fixture_sets, init_source_adapter
from agevidence.bundle import Bundle
from agevidence.cli import app
from agevidence.identifiers import Identifier, link
from agevidence.ingest import ingest, ingest_async, ingest_dataframe, ingest_file, ingest_many, ingest_stream
from agevidence.primitives import AssetState, Attachment, CalibrationRecord, DerivedObservation, ExternalObject, ModelRun, Observation, ProductLot, Transformation
from agevidence.provenance import lineage
from agevidence.rules import Rule
from agevidence.series import series
from agevidence.snapshots import check_snapshot, create_snapshot
from agevidence.testing import assert_mapping_complete, assert_no_silent_field_loss, assert_rust_conformant
from agevidence.units import Quantity, compatible_units, normalize_unit, validate_unit


runner = CliRunner()


def native_observation(**overrides):
    record = {
        "animal_id": "animal:1",
        "observable": "liveweight",
        "value": 481.4,
        "unit": "kg",
        "observed_at": "2026-08-12T00:00:00Z",
        "gateway_rssi": -71,
    }
    record.update(overrides)
    return record


def test_ingest_result_is_ergonomic_and_preserves_unmapped_fields():
    result = ingest(native_observation(), extension_namespace="com.example.scale")

    assert result.primitive_type == "Observation"
    assert result.native["animal_id"] == "animal:1"
    assert result.mapping.confidence == "high"
    assert result.unmapped == {"gateway_rssi": -71}
    assert result.primitive["metadata"]["extensions"]["com.example.scale"]["gateway_rssi"] == -71
    assert result.warnings
    assert result.errors == []
    assert result.ok
    assert "Observation" in result.explain().summary
    assert json.loads(result.to_json())["ok"] is True
    result.raise_for_findings("error")
    with pytest.raises(Exception):
        result.raise_for_findings("warning")


def test_ingest_batch_file_stream_and_dataframe_support(tmp_path):
    records = [native_observation(animal_id="animal:1"), native_observation(animal_id="animal:2")]
    dataset = ingest_many(records)
    assert dataset.count == 2
    assert dataset.valid == 2
    assert dataset.primitive_types == {"Observation": 2}
    assert len(dataset.to_primitives()) == 2
    assert [item.primitive_type for item in ingest_stream(records)] == ["Observation", "Observation"]

    jsonl = tmp_path / "records.jsonl"
    jsonl.write_text("\n".join(json.dumps(record) for record in records), encoding="utf-8")
    assert ingest_file(jsonl).count == 2

    csv_path = tmp_path / "records.csv"
    csv_path.write_text("animal_id,observable,value,unit,observed_at\nanimal:1,liveweight,481.4,kg,2026-08-12T00:00:00Z\n", encoding="utf-8")
    csv_default = ingest_file(csv_path)
    assert csv_default.count == 1
    assert csv_default.results[0].native["value"] == "481.4"
    csv_coerced = ingest_file(csv_path, coerce=True)
    assert csv_coerced.results[0].native["value"] == 481.4

    class FakeDataFrame:
        def to_dict(self, orient):
            assert orient == "records"
            return records

    assert ingest_dataframe(FakeDataFrame()).valid == 2


def test_ingest_async_supports_async_iterables():
    async def records():
        yield native_observation()

    async def collect():
        return [result async for result in ingest_async(records())]

    results = asyncio.run(collect())
    assert results[0].primitive_type == "Observation"


def test_extension_namespace_validation():
    with pytest.raises(ValueError):
        ingest(native_observation(), extension_namespace="not-a-namespace")


def test_nested_mapping_paths_are_classified_and_preserved():
    result = ingest(
        {
            "animal_id": "animal:1",
            "observable": "liveweight",
            "value": 481.4,
            "unit": "kg",
            "observed_at": "2026-08-12T00:00:00Z",
            "sensor": {"id": "scale-1", "calibration_reference": "sha256:calibration"},
            "gateway": {"rssi": -71, "firmware": "4.2.1"},
        },
        extension_namespace="com.example.scale",
    )

    coverage = {item.source_field: item.status for item in result.mapping.field_coverage}
    assert coverage["sensor.id"] == "canonical_mapped"
    assert coverage["sensor.calibration_reference"] == "canonical_mapped"
    assert coverage["gateway.rssi"] == "extension_preserved"
    assert result.unmapped["gateway.firmware"] == "4.2.1"
    assert result.primitive["metadata"]["extensions"]["com.example.scale"]["gateway.rssi"] == -71


def test_adapter_scaffold_coverage_and_compare(tmp_path):
    scaffold = init_source_adapter("dit-udose", out=tmp_path / "dit_udose")
    assert Path(scaffold.files["adapter"]).exists()

    adapter_path = tmp_path / "adapter.py"
    adapter_path.write_text(
        """from agevidence.adapters import Adapter
from agevidence import ingest

class PreserveAdapter(Adapter):
    def map(self, record):
        return ingest(record, extension_namespace="com.example.scale").primitive
""",
        encoding="utf-8",
    )
    fixtures = tmp_path / "fixtures"
    fixtures.mkdir()
    (fixtures / "one.json").write_text(json.dumps(native_observation()), encoding="utf-8")

    coverage = adapter_coverage(f"{adapter_path}:PreserveAdapter", fixtures)
    assert coverage.silently_lost_count == 0
    assert_no_silent_field_loss(coverage)

    bare_adapter_path = tmp_path / "bare_adapter.py"
    bare_adapter_path.write_text(
        """from agevidence.adapters import Adapter
from agevidence.primitives import Observation

class BareAdapter(Adapter):
    def map(self, record):
        return Observation(subject=record["animal_id"], observable=record["observable"], value=record["value"], unit=record["unit"], observed_at=record["observed_at"])
""",
        encoding="utf-8",
    )
    bare_coverage = adapter_coverage(f"{bare_adapter_path}:BareAdapter", fixtures)
    assert bare_coverage.silently_lost_count == bare_coverage.source_field_count
    assert "gateway_rssi" in bare_coverage.silently_lost_fields

    old = tmp_path / "old"
    new = tmp_path / "new"
    old.mkdir()
    new.mkdir()
    (old / "one.json").write_text(json.dumps({"dose_ml": 1}), encoding="utf-8")
    (new / "one.json").write_text(json.dumps({"dose_ml": "1", "gateway_firmware": "4.2.1"}), encoding="utf-8")
    comparison = compare_fixture_sets(old, new)
    assert comparison.breaking
    assert "dose_ml" in comparison.changed_fields


def test_cli_infer_adapter_snapshot_and_compatibility(tmp_path):
    record = tmp_path / "weight.json"
    record.write_text(json.dumps(native_observation()), encoding="utf-8")
    mapping = tmp_path / "mapping.yaml"

    infer_result = runner.invoke(app, ["infer", str(record), "--write", str(mapping), "--format", "table"])
    assert infer_result.exit_code == 0
    assert "Likely primitive: Observation" in infer_result.stdout
    assert mapping.exists()

    scaffold_result = runner.invoke(app, ["adapter", "init", "meq-probe", "--out", str(tmp_path / "meq"), "--format", "json"])
    assert scaffold_result.exit_code == 0
    assert "adapter.py" in scaffold_result.stdout

    snapshot = tmp_path / "snapshot.json"
    create_result = runner.invoke(app, ["snapshot", "create", str(record), "--out", str(snapshot)])
    assert create_result.exit_code == 0
    check_result = runner.invoke(app, ["snapshot", "check", str(record), str(snapshot)])
    assert check_result.exit_code == 0

    compatibility_result = runner.invoke(app, ["compatibility"])
    assert compatibility_result.exit_code == 0
    assert "Rust" in compatibility_result.stdout


def test_new_primitives_lineage_bundle_assessment_rules_and_quality(tmp_path):
    calibration = CalibrationRecord(instrument="device:scale-1", calibrated_at="2026-08-01T00:00:00Z", certificate_hash="sha256:abc")
    lot = ProductLot(product="additive:x", lot="lot-1", manufacturer="Example")
    transform = Transformation(name="water_flow_to_additive_mass", version="2.1", implementation="dit.udose")
    derived = DerivedObservation(
        subject="herd:A27",
        observable="additive_delivered",
        value=800,
        unit="g",
        observed_at="2026-08-12T00:00:00Z",
        inputs=[calibration.local_digest()],
        transformation=transform,
    )
    assert agevidence.quality([calibration, lot, derived]).completeness == 1.0

    graph = lineage()
    graph.derive(derived, from_=calibration)
    assert not graph.validate()
    assert graph.roots()[0].primitive_type == "CalibrationRecord"

    bundle = Bundle().add([calibration, lot, derived])
    manifest = bundle.to_manifest()
    assert manifest["contract_version"] == "athian.agevidence.bundle.local.v1"
    assert bundle.validate_manifest().passed
    manifest["records"][0]["local_digest"] = "sha256:tampered"
    assert not bundle.validate_manifest(manifest).passed
    assert bundle.write(tmp_path / "bundle.json").exists()
    assert bundle.summary().records == 3

    frame = agevidence.frame([derived])
    assert frame.subject("herd:A27").period["start"] == "2026-08-12T00:00:00Z"
    assert frame.aggregate("value", by="subject", reducer="mean") == {"herd:A27": 800.0}
    frame_graph = frame.lineage()
    assert derived.inputs[0] in frame_graph.nodes
    assert any(edge.relation == "generated_by" for edge in frame_graph.edges)
    assert Rule(id="coverage", require={"coverage": {">=": 1.0}}).evaluate(frame).passed


def test_units_identifiers_offline_series_diff_replay_and_snapshots(tmp_path):
    assert normalize_unit("kilograms") == "kg"
    assert validate_unit("ppm")
    assert "lb" in compatible_units("kg")
    assert round(Quantity(1, "kg").to("lb").normalized_value, 3) == 2.205

    linked = link(Identifier(namespace="dit", value="mob-782"), "aaco:A27")
    assert linked["identifiers"][0]["namespace"] == "dit"

    queue = agevidence.Queue(tmp_path / "agevidence.db")
    sequence = queue.put(native_observation())
    assert sequence == 1
    assert queue.pending()[0]["sync_status"] == "pending"

    class Client:
        def __init__(self):
            self.signatures = []

        def submit_event(self, event, *, source, timestamp, signature):
            self.signatures.append(signature)
            return {"event": event, "source": source, "timestamp": timestamp}

    client = Client()
    blocked = queue.flush(client)
    assert blocked == {"submitted": 0, "failed": 0, "blocked": 1}
    assert queue.pending()[0]["sync_status"] == "pending"
    submitted = queue.flush(client, signature_provider=lambda row: "sha256=signed")
    assert submitted == {"submitted": 1, "failed": 0, "blocked": 0}
    assert client.signatures == ["sha256=signed"]

    records = [
        ingest(native_observation(observed_at="2026-08-12T00:00:00Z")),
        ingest(native_observation(observed_at="2026-08-12T00:10:00Z")),
        ingest(native_observation(observed_at="2026-08-12T00:30:00Z")),
    ]
    assert series(records).gaps(expected_interval_seconds=600)

    changed = ingest(native_observation(value=482.0))
    assert agevidence.diff(records[0], changed).normalization
    assert agevidence.replay(records[0]).results

    fixture = tmp_path / "fixture.json"
    fixture.write_text(json.dumps(native_observation()), encoding="utf-8")
    snapshot = tmp_path / "snapshot.json"
    report = create_snapshot(fixture, snapshot)
    assert report.records == 1
    assert check_snapshot(fixture, snapshot).passed


def test_model_run_reproducibility_and_mapping_helper():
    run = ModelRun(
        model_id="pasturekey",
        model_version="v1",
        implementation_digest="sha256:model",
        input_commitments=["sha256:input"],
        parameters={"threshold": 0.8},
        execution_environment={"runtime": "python"},
        outputs=[{"id": "out"}],
    )
    assert run.reproducibility().status == "complete"

    result = ingest(native_observation())
    assert_mapping_complete(result)


def test_supporting_primitives_are_rust_conformant():
    command = "cargo run --quiet -p baink-cli --"
    calibration = CalibrationRecord(instrument="device:scale-1", calibrated_at="2026-08-01T00:00:00Z", certificate_hash="sha256:abc")
    lot = ProductLot(product="additive:x", lot="lot-1", manufacturer="Example")
    asset = AssetState(asset="device:scale-1", state={"status": "active"}, effective_at="2026-08-12T00:00:00Z")
    transform = Transformation(name="water_flow_to_additive_mass", version="2.1", implementation="dit.udose")
    derived = DerivedObservation(
        subject="herd:A27",
        observable="additive_delivered",
        value=800,
        unit="g",
        observed_at="2026-08-12T00:00:00Z",
        inputs=[calibration.local_digest()],
        transformation=transform,
    )
    attachment = Attachment(path="certificate.pdf", media_type="application/pdf")
    external = ExternalObject(uri="s3://example-bucket/object.tif", sha256="sha256:object")

    for primitive in [calibration, lot, asset, derived, transform, attachment, external]:
        assert_rust_conformant(primitive, command=command)

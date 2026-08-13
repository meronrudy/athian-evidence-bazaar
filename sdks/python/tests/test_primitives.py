from __future__ import annotations

import json
from pathlib import Path

from jsonschema import Draft202012Validator

from agevidence.livestock import FeedAdditive, Weight
from agevidence.primitives import (
    InterventionEvent,
    ModelRun,
    Observation,
    OperationalEvent,
    SourceRecord,
    SpatialObservation,
)


def test_observation_round_trips_and_matches_schema():
    source = SourceRecord(source_system="scale", record_id="weight-1", observed_at="2026-08-12T14:05:11Z")
    observation = Observation(
        subject="animal:982000001234",
        observable="liveweight",
        value=481.4,
        unit="kg",
        observed_at="2026-08-12T14:05:11Z",
        source_records=[source],
    )
    payload = observation.to_payload()
    schema = json.loads((Path(__file__).resolve().parents[3] / "specs/agevidence/schemas/athian.agevidence.observation.v1.json").read_text())

    Draft202012Validator(schema).validate(payload)
    assert Observation.model_validate(payload).local_digest() == observation.local_digest()
    assert observation.normalized_json() == observation.normalized_json()


def test_all_primitive_constructors_have_distinct_types():
    source = SourceRecord(source_system="demo", record_id="source-1", observed_at="2026-08-12T00:00:00Z")

    primitives = [
        source,
        Observation(subject="animal:1", observable="liveweight", value=1, unit="kg", observed_at="2026-08-12T00:00:00Z"),
        SpatialObservation(geometry={"type": "Point", "coordinates": [151.2, -33.8]}, observable="foo", value=1, unit="kg_dm_ha", observed_at="2026-08-12T00:00:00Z"),
        InterventionEvent(target="herd:H1", intervention="product:x", quantity=1, unit="kg", occurred_at="2026-08-12T00:00:00Z"),
        OperationalEvent(machine="machine:1", operation="spot_spray", started_at="2026-08-12T00:00:00Z", completed_at="2026-08-12T00:05:00Z"),
        ModelRun(model_id="pasturekey", model_version="v1", inputs=[], outputs=[]),
    ]

    assert {item.to_payload().get("primitive_type", "ModelRun") for item in primitives} >= {
        "SourceRecord",
        "Observation",
        "SpatialObservation",
        "InterventionEvent",
        "OperationalEvent",
    }


def test_livestock_objects_project_to_generic_primitives():
    weight = Weight(subject_id="animal:1", value="481.4", unit="kg", measured_at="2026-08-12T00:00:00Z")
    additive = FeedAdditive(
        intervention_id="int-1",
        intervention_type="intervention.feed_additive",
        product_id="product:seafeed",
        product_batch="SF-90231",
        dose_or_quantity="2.4",
        unit="kg",
        occurred_at="2026-08-12T00:00:00Z",
    )

    assert weight.to_observation().primitive_type == "Observation"
    assert additive.to_intervention_event(target="herd:H1").batch == "SF-90231"

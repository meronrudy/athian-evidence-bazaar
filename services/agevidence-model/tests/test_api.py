from fastapi.testclient import TestClient

from athian_agevidence.api import app
from test_contracts import request_payload


def test_evidence_runs_endpoint_returns_fixture_response():
    client = TestClient(app)

    response = client.post("/v1/evidence-runs", json=request_payload().model_dump())

    assert response.status_code == 200
    body = response.json()
    assert body["model_run"]["adapter_id"] == "qwen3.5-4b-reference"
    assert len(body["gaps"]) == 3

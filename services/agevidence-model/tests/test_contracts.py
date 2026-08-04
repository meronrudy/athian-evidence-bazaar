from athian_agevidence.adapters.fixture import FixtureAdapter
from athian_agevidence.contracts import EvidenceRunRequest
from athian_agevidence.gap_detection import material_gap_count
from athian_agevidence.normalization import normalize_response

import pytest


def request_payload():
    return EvidenceRunRequest.model_validate(
        {
            "adapter_id": "qwen3.5-4b-reference",
            "task": "protocol_evidence_extraction",
            "project": {
                "id": "project-001",
                "claim": "The intervention reduces enteric methane.",
            },
            "protocol": {"code": "ATH-LI-CH4", "version": "v1"},
            "country": {
                "country_code": "CA",
                "adapter_id": "athian-country-ca-beef-v1",
                "adapter_version": "v1",
                "method_id": "CA-FED-REME-BC",
                "method_version": "v1.0",
            },
            "country_context": {
                "species": "species.beef_cattle",
                "production_system": "production.confined_feeding",
                "intervention_class": "intervention.ration_reformulation",
            },
            "documents": [
                {
                    "document_id": "trial-report-001",
                    "commitment": "sha256:trial-report",
                    "controlled_uri": "evidence://trial-report-001",
                }
            ],
            "generation": {"temperature": 0, "seed": 42},
        }
    )


def test_fixture_adapter_preserves_source_references():
    response = FixtureAdapter().run(request_payload())

    assert len(response.candidates) == 7
    assert response.candidates[0].source_references[0].document_id == "invoice-001"
    assert material_gap_count(response) == 2


def test_model_response_declares_limitations():
    response = FixtureAdapter().run(request_payload())

    assert "not a scientific or verification determination" in response.limitations[0]


def test_country_context_is_authority_neutral():
    request = request_payload()

    assert request.country.country_code == "CA"
    assert "government_eligible" not in request.model_dump_json()


def test_model_output_rejects_authority_states():
    response = FixtureAdapter().run(request_payload()).model_dump(mode="json")
    response["government_eligible"] = True

    with pytest.raises(ValueError, match="authority field"):
        normalize_response(response)

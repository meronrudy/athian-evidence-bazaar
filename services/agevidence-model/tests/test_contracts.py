from athian_agevidence.adapters.fixture import FixtureAdapter
from athian_agevidence.contracts import EvidenceRunRequest
from athian_agevidence.gap_detection import material_gap_count


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

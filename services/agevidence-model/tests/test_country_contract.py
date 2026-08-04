from athian_agevidence.contracts import EvidenceRunRequest


def test_country_context_is_versioned_and_optional() -> None:
    request = EvidenceRunRequest.model_validate(
        {
            "adapter_id": "qwen3.5-4b-reference",
            "task": "protocol_evidence_extraction",
            "project": {
                "id": "project-1",
                "claim": "The intervention reduces enteric methane.",
                "country_context": {
                    "species": "beef_cattle",
                    "production_system": "confined_beef_feeding",
                },
            },
            "country": {
                "code": "CA",
                "program_id": 1,
                "adapter_id": "athian-country-ca-beef-v1",
                "adapter_version": "v1",
                "method_code": "CA-FED-REME-BC",
                "method_version": "v1.0",
                "determination_role": "Athian compatibility assessment only",
            },
            "protocol": {"code": "CA-FED-REME-BC", "version": "v1.0"},
            "documents": [
                {
                    "document_id": "animal-cohort-1",
                    "commitment": "sha256:example",
                    "controlled_uri": "evidence://animal-cohort-1",
                    "evidence_type": "animal_cohort",
                }
            ],
        }
    )

    assert request.country is not None
    assert request.country.code == "CA"
    assert request.project.country_context["species"] == "beef_cattle"
    assert request.documents[0].evidence_type == "animal_cohort"

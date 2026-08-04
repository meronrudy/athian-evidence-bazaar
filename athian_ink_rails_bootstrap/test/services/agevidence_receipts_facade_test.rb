require "test_helper"

class AgevidenceReceiptsFacadeTest < ActiveSupport::TestCase
  test "issues model execution receipt through facade" do
    issued = InkReceipts.issue_model_execution(
      payload: {
        base_model_id: "Qwen/Qwen3.5-4B",
        weights_digest: "sha256:weights",
        adapter_id: "qwen3.5-4b-reference",
        adapter_digest: "sha256:adapter",
        model_license: "reference",
        runtime: "fixture",
        generation_config: { temperature: 0 },
        system_prompt_digest: "sha256:prompt",
        retrieval_corpus_digest: "sha256:retrieval",
        source_document_commitments: ["sha256:doc"],
        normalized_output_digest: "sha256:output",
        policy_version: "ATH-AGEV-POLICY-v1",
        limitations: ["candidate evidence only"],
        execution_timestamp: Time.current.iso8601,
        issuer: "Athian Test",
        signer: "did:key:test"
      },
      issuer: "Athian Test",
      signer: "did:key:test"
    )

    assert_equal "model_execution_receipt", issued.fetch(:receipt_type)
    assert_equal "athian.agevidence.model_execution.v1", issued.fetch(:schema_id)
  end
end

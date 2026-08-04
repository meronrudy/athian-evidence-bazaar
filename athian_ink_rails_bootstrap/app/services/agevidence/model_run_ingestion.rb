module Agevidence
  class ModelRunIngestion
    def initialize(project:, model_adapter:, client: ModelServiceClient.new)
      @project = project
      @model_adapter = model_adapter
      @client = client
    end

    def call
      response = client.run_evidence(project: project, adapter: model_adapter)
      metadata = response.fetch("model_run")

      ActiveRecord::Base.transaction do
        run = project.model_runs.create!(
          model_adapter: model_adapter,
          task: "protocol_evidence_extraction",
          status: "completed",
          prompt_digest: metadata["prompt_digest"],
          retrieval_digest: metadata["retrieval_digest"],
          input_manifest: { documents: project.source_documents },
          normalized_output: response,
          output_digest: metadata["normalized_output_digest"],
          runtime_metadata: metadata,
          started_at: metadata["started_at"],
          completed_at: metadata["completed_at"]
        )

        response.fetch("candidates").each do |candidate|
          run.evidence_candidates.create!(
            candidate_type: candidate.fetch("candidate_type"),
            claim_text: candidate.fetch("claim_text"),
            source_references: candidate.fetch("source_references"),
            model_confidence: candidate.fetch("confidence"),
            review_status: candidate.fetch("status")
          )
        end

        response.fetch("gaps").each do |gap|
          run.evidence_gaps.create!(
            gap_type: gap.fetch("gap_type"),
            requirement: gap.fetch("requirement"),
            description: gap.fetch("description"),
            severity: gap.fetch("severity"),
            source_context: gap.fetch("source_context", {}),
            resolution_status: "open"
          )
        end

        project.update!(integration_status: "model_ready")
        run
      end
    end

    private

    attr_reader :project, :model_adapter, :client
  end
end

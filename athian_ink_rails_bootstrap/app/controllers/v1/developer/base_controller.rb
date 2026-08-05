module V1
  module Developer
    class BaseController < ActionController::API
      private

      def developer_integration_source
        @developer_integration_source ||= IntegrationSource.find_or_create_by!(key: "agevidence_developer_api") do |source|
          source.name = "AgEvidence Developer API"
          source.environment = Rails.env
          source.status = "active"
          source.signature_algorithm = "hmac_sha256"
          source.verification_secret_ciphertext = "developer-api-internal-secret"
          source.allowed_event_types = ["source.manifest_available"]
          source.metadata_json = {
            authority_boundary: "Self-service developer API source; operational authority stays outside Rails."
          }
        end
      end

      def find_project!
        id = params[:project_id] || params[:project_external_id] || params[:external_id]
        Agevidence::DeveloperProject.find_by(id: id) || mapped_project(id) || raise(ActiveRecord::RecordNotFound)
      end

      def mapped_project(external_id)
        return nil if external_id.blank?

        ExternalObjectMapping.find_by(
          integration_source: developer_integration_source,
          external_object_type: "project",
          external_object_id: external_id,
          internal_record_type: "Agevidence::DeveloperProject"
        )&.internal_record
      end

      def project_payload(project)
        {
          id: project.id,
          name: project.name,
          developer_account: project.developer_account.name,
          target_claim: project.target_claim,
          project_type: project.project_type,
          protocol_status: project.protocol_status,
          integration_status: project.integration_status,
          evidence_graph_root: project.evidence_graph_root,
          source_records_url: v1_developer_project_source_records_path(project),
          model_runs_url: v1_developer_project_model_runs_path(project),
          artifacts_url: v1_developer_project_artifacts_path(project),
          authority_boundary: "Rails stores developer projections. INK receipts and local verification remain the trust boundary."
        }
      end

      def source_record_payload(record)
        {
          id: record.id,
          document_id: record.document_id,
          evidence_type: record.evidence_type,
          evidence_class: record.evidence_class,
          source_system: record.source_system,
          controlled_uri: record.controlled_uri,
          commitment: record.commitment,
          disclosure_status: record.disclosure_status,
          status: record.status,
          source_event_id: record.source_event&.external_event_id,
          operation_id: record.source_event&.current_operation&.external_id,
          created_at: record.created_at&.iso8601
        }
      end

      def candidate_payload(candidate)
        {
          id: candidate.id,
          model_run_id: candidate.model_run_id,
          candidate_type: candidate.candidate_type,
          claim_text: candidate.claim_text,
          source_references: candidate.source_references,
          model_confidence: candidate.model_confidence,
          review_status: candidate.review_status,
          review_notes: candidate.review_notes,
          reviewed_by: candidate.reviewed_by,
          reviewed_at: candidate.reviewed_at&.iso8601,
          authority_boundary: "Model output remains review_required until a human decision is appended."
        }
      end

      def model_run_payload(run)
        {
          id: run.id,
          project_id: run.developer_project_id,
          adapter_id: run.model_adapter.adapter_id,
          base_model_id: run.model_adapter.base_model_id,
          task: run.task,
          status: run.status,
          prompt_digest: run.prompt_digest,
          retrieval_digest: run.retrieval_digest,
          output_digest: run.output_digest,
          limitations: run.limitations,
          candidates: run.evidence_candidates.order(:id).map { |candidate| candidate_payload(candidate) },
          gaps: run.evidence_gaps.order(:id).map { |gap| gap_payload(gap) },
          completed_at: run.completed_at&.iso8601
        }
      end

      def gap_payload(gap)
        {
          id: gap.id,
          gap_type: gap.gap_type,
          requirement: gap.requirement,
          description: gap.description,
          severity: gap.severity,
          resolution_status: gap.resolution_status
        }
      end

      def quote_payload(quote)
        {
          quote_id: quote.external_id,
          product_code: quote.product_code,
          currency: quote.currency,
          amount: quote.amount_cents,
          pricing_version: quote.pricing_version,
          breakdown: quote.breakdown_json,
          status: quote.status,
          expires_at: quote.expires_at&.iso8601,
          accepted_at: quote.accepted_at&.iso8601,
          notice: Agevidence::ProductCatalog.notice
        }
      end

      def order_payload(order)
        {
          order_id: order.external_id,
          quote_id: order.pricing_quote.external_id,
          product_code: order.product_code,
          status: order.status,
          currency: order.currency,
          amount: order.amount_cents,
          checkout_url: order.checkout_url,
          checkout_completed_at: order.checkout_completed_at&.iso8601,
          assembled_at: order.assembled_at&.iso8601,
          artifact: artifact_payload(order),
          notice: "Sandbox checkout only. Payment state authorizes demo assembly but is not collected or recognized revenue."
        }
      end

      def artifact_payload(order)
        return nil unless order.evidence_bundle

        {
          artifact_id: "artifact_#{order.evidence_bundle.id}",
          bundle_id: order.evidence_bundle.id,
          status: order.evidence_bundle.status,
          verification_status: order.evidence_bundle.verification_status,
          receipt_root: order.metadata_json["receipt_root"],
          download_url: order.metadata_json["download_url"],
          verification_command: order.metadata_json["verification_command"],
          limitations: order.evidence_bundle.manifest["limitations"]
        }
      end

      def render_error(code, status:, message: nil)
        render json: { error: { code: code, message: message.presence || code.to_s.humanize } }, status: status
      end

      def campaign_activation_recorder
        ::Campaign::ActivationRecorder.from_headers(request.headers)
      end

      def record_campaign_activation
        yield campaign_activation_recorder
      rescue StandardError
        nil
      end
    end
  end
end

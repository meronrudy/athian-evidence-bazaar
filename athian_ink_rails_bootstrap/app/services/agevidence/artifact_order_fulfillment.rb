module Agevidence
  class ArtifactOrderFulfillment
    def initialize(order:)
      @order = order
      @project = order.developer_project
    end

    def call
      raise "Artifact order must be paid through sandbox checkout before assembly." unless order.status == "paid"

      order.update!(status: "assembling")
      ensure_lightweight_avsa!
      engagement = ensure_engagement!
      bundle = ArtifactAssembler.new(engagement: engagement).call
      order.update!(
        artifact_engagement: engagement,
        evidence_bundle: bundle,
        status: "fulfilled",
        assembled_at: Time.current,
        metadata_json: artifact_metadata(bundle)
      )
      dispatch_result(bundle)
      order
    rescue StandardError => e
      if order.persisted? && %w[paid assembling verification_pending].include?(order.status)
        order.update!(status: "verification_pending", metadata_json: order.metadata_json.merge("last_error" => e.message))
      end
      raise e
    end

    private

    attr_reader :order, :project

    def ensure_lightweight_avsa!
      return project.avsa if project.avsa

      protocol = project.protocol || Protocol.find_or_create_by!(code: "ATH-DEVELOPER-OS") do |record|
        record.name = "Athian Developer OS Projection Protocol"
        record.version = "v1"
        record.governance_version = "ATH-DEVELOPER-OS-2026.1"
        record.status = "active"
        record.description = "Lightweight scaffold protocol used only to anchor self-service artifact receipts."
      end

      avsa = Avsa.create!(
        protocol: protocol,
        external_id: "AVSA-DEVELOPER-OS-#{project.id}",
        title: project.name,
        producer_name: project.developer_account.name,
        status: "in_progress",
        verified_quantity: 0,
        unit: "tCO2e",
        local_verification_status: "indeterminate",
        methodology_name: protocol.name,
        methodology_version: protocol.version
      )
      project.update!(avsa: avsa, protocol: protocol)
      avsa
    end

    def ensure_engagement!
      return order.artifact_engagement if order.artifact_engagement

      product = ProductCatalog.fetch(order.product_code)
      project.artifact_engagements.create!(
        product_code: order.product_code,
        pipeline_stage: "scoped",
        billing_type: product.fetch("billing_type"),
        list_price_cents: product.fetch("base_planning_price_cents"),
        quoted_price_cents: order.amount_cents,
        currency: order.currency,
        commercial_status: "proposed",
        started_on: Date.current
      )
    end

    def artifact_metadata(bundle)
      {
        "artifact_id" => "artifact_#{bundle.id}",
        "bundle_id" => bundle.id,
        "profile" => bundle.commercial_product_code,
        "receipt_root" => project.evidence_graph_root,
        "integrity_status" => bundle.verification_status,
        "policy_compatibility" => latest_determination_status,
        "review_status" => review_status,
        "reliance_status" => bundle.reliance_status,
        "download_url" => "/bundle_exports",
        "verification_command" => "ink verify-bundle #{bundle.artifact_filename}"
      }
    end

    def latest_determination_status
      project.country_determinations.order(evaluated_at: :desc).first&.status || "unassigned"
    end

    def review_status
      pending = EvidenceCandidate.joins(:model_run).where(agevidence_model_runs: { developer_project_id: project.id }, review_status: "review_required").exists?
      pending ? "review_required" : "completed"
    end

    def dispatch_result(bundle)
      mapping = ExternalObjectMapping.find_by(
        external_object_type: "project",
        internal_record_type: "Agevidence::DeveloperProject",
        internal_record_id: project.id
      )
      return unless mapping

      Integrations::WebhookDispatcher.new(
        integration_source: mapping.integration_source,
        event_type: "artifact.ready",
        payload: artifact_metadata(bundle).merge("external_project_id" => mapping.external_object_id)
      ).call
    end
  end
end

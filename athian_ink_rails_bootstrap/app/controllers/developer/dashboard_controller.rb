class Developer::DashboardController < ApplicationController
  def index
    @api_keys = ApiKey.all
    @api_logs = ApiLog.all
    @webhooks = Webhook.all
    @schemas = Schema.all
    @avsa = canonical_avsa
    @country_program = Agevidence::CountryProgram.includes(:country_adapters).order(:country_code, :name).first
    @adapter = @country_program&.country_adapters&.order(:adapter_id, :version)&.first
    @latest_bundle = EvidenceBundle.includes(:avsa).order(generated_at: :desc).first
    @latest_determination = Agevidence::CountryDetermination.includes(:developer_project, :country_adapter, :receipt).order(evaluated_at: :desc).first
    @recent_runs = VerificationRun.includes(:avsa, :receipt).recent_first.limit(4)
    @system_chain = [
      {
        eyebrow: "Source evidence",
        title: "#{EvidenceItem.count} evidence items",
        identifier: "#{Receipt.count} receipts",
        status: EvidenceItem.where.not(status: "present").exists? ? "human_review" : "valid",
        meta: [
          ["AVSAs", Avsa.count, true],
          ["Source systems", EvidenceItem.distinct.count(:source_system), true],
          ["Open items", EvidenceItem.where.not(status: "present").count, true]
        ],
        basis_url: @avsa ? avsa_path(@avsa) : evidence_index_path
      },
      {
        eyebrow: "Program basis",
        title: @country_program&.name || "Country program pending",
        identifier: @adapter&.adapter_id || "adapter.pending",
        status: @adapter&.status || "draft",
        meta: [
          ["Country", @country_program&.country_code || "NA", true],
          ["Adapter", @adapter&.version || "pending", true],
          ["Required evidence", @adapter&.required_evidence&.size || 0, true]
        ],
        basis_url: @country_program ? agevidence_country_program_path(@country_program) : agevidence_country_programs_path
      },
      {
        eyebrow: "Reliance",
        title: "#{EvidenceBundle.count} bundles",
        identifier: @latest_bundle&.artifact_filename || "bundle.pending",
        status: @latest_bundle&.verification_status || "draft",
        meta: [
          ["Determinations", Agevidence::CountryDetermination.count, true],
          ["Reliance events", Agevidence::RelianceEvent.count, true],
          ["Latest", @latest_determination ? "DET-#{@latest_determination.id}" : "Pending", true]
        ],
        basis_url: @latest_determination ? agevidence_determination_path(@latest_determination) : agevidence_determinations_path
      }
    ]
  end
end

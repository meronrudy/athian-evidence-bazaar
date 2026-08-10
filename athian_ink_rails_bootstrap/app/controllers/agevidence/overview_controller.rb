module Agevidence
  class OverviewController < BaseController
    def show
      @accounts = DeveloperAccount.includes(:developer_projects).order(:name)
      @projects = DeveloperProject.includes(:developer_account, :protocol, :avsa).order(updated_at: :desc)
      @model_runs = ModelRun.includes(:developer_project, :model_adapter).order(created_at: :desc).limit(5)
      @engagements = ArtifactEngagement.includes(:developer_project, :evidence_bundle).order(created_at: :desc).limit(6)
      @reliance_events = RelianceEvent.includes(:artifact_engagement, :evidence_bundle).order(occurred_at: :desc).limit(5)
      @projection = RevenueProjection.from_config
      @product_notice = product_notice
      @latest_project = @projects.first
      @latest_determination = CountryDetermination.includes(:developer_project, :country_adapter, :receipt).order(evaluated_at: :desc).first
      @latest_engagement = @engagements.first
      @system_chain = [
        {
          eyebrow: "Source evidence",
          title: "#{SourceRecord.count} source records",
          identifier: "#{EvidenceCandidate.count} candidates",
          status: EvidenceCandidate.where(review_status: "review_required").exists? ? "human_review" : "valid",
          meta: [
            ["Projects", @projects.count, true],
            ["Model runs", ModelRun.count, true],
            ["Review queue", EvidenceCandidate.where(review_status: "review_required").count, true]
          ],
          basis_url: @latest_project ? agevidence_developer_project_path(@latest_project) : agevidence_developer_projects_path
        },
        {
          eyebrow: "Program basis",
          title: "#{CountryProgram.count} country programs",
          identifier: CountryAdapter.order(:country_code, :adapter_id).first&.adapter_id || "adapter.pending",
          status: "valid",
          meta: [
            ["Adapters", CountryAdapter.count, true],
            ["Methods", CountryMethodVersion.count, true],
            ["Policies", CountryClaimPolicy.count, true]
          ],
          basis_url: agevidence_country_programs_path
        },
        {
          eyebrow: "Reliance",
          title: "#{ArtifactEngagement.count} artifact engagements",
          identifier: @latest_determination ? "DET-#{@latest_determination.id}" : "determination.pending",
          status: @latest_determination&.status || "draft",
          meta: [
            ["Determinations", CountryDetermination.count, true],
            ["Reliance events", RelianceEvent.count, true],
            ["Orders", ArtifactOrder.count, true]
          ],
          basis_url: @latest_determination ? agevidence_determination_path(@latest_determination) : agevidence_determinations_path
        }
      ]
    end
  end
end

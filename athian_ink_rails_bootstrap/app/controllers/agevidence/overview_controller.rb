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
    end
  end
end

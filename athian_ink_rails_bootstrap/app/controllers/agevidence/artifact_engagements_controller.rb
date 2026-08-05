module Agevidence
  class ArtifactEngagementsController < BaseController
    before_action :set_project
    before_action :set_engagement, only: :show

    def index
      @engagements = @project.artifact_engagements.includes(:evidence_bundle).order(created_at: :desc)
      @products = products
      @product_notice = product_notice
    end

    def new
      @engagement = @project.artifact_engagements.new(currency: "USD", commercial_status: "illustrative")
      @products = products
      @product_notice = product_notice
    end

    def create
      product = ProductCatalog.fetch(params.require(:product_code))
      @engagement = @project.artifact_engagements.create!(
        product_code: params.require(:product_code),
        pipeline_stage: "scoped",
        billing_type: product.fetch("billing_type"),
        list_price_cents: product.fetch("base_planning_price_cents"),
        quoted_price_cents: params[:quoted_price_cents].presence || product.fetch("base_planning_price_cents"),
        currency: "USD",
        commercial_status: "illustrative",
        started_on: Date.current
      )
      ArtifactAssembler.new(engagement: @engagement).call if params[:assemble] == "1"
      record_campaign_activation { |recorder| recorder.record_artifact_assembled(@engagement) } if params[:assemble] == "1"
      redirect_to agevidence_developer_project_artifact_engagement_path(@project, @engagement), notice: "Premium artifact engagement created."
    rescue ActiveRecord::RecordInvalid, KeyError, RuntimeError, InkReceipts::Error => e
      @products = products
      @product_notice = product_notice
      flash.now[:alert] = e.message
      render :new, status: :unprocessable_entity
    end

    def show
      @products = products
      @product_notice = product_notice
      @reliance_events = @engagement.reliance_events.order(occurred_at: :desc)
    end

    private

    def set_project
      @project = DeveloperProject.find(params[:developer_project_id])
    end

    def set_engagement
      @engagement = @project.artifact_engagements.includes(:evidence_bundle).find(params[:id])
    end
  end
end

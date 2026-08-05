module Agevidence
  class PricingQuotesController < BaseController
    before_action :set_project

    def new
      @products = products
      @product_notice = product_notice
      @quote_scope = default_scope
    end

    def create
      quote = PricingEngine.new(
        project: @project,
        product_code: quote_params.require(:product_code),
        scope: quote_params[:scope].presence || {}
      ).quote
      record_campaign_activation { |recorder| recorder.record_quote_created(quote) }
      redirect_to agevidence_developer_project_pricing_quote_path(@project, quote), notice: "Sandbox quote created."
    rescue ActiveRecord::RecordInvalid, ActionController::ParameterMissing, KeyError => e
      @products = products
      @product_notice = product_notice
      @quote_scope = params[:pricing_quote].respond_to?(:[]) ? params[:pricing_quote][:scope].presence || default_scope : default_scope
      flash.now[:alert] = e.message
      render :new, status: :unprocessable_entity
    end

    def show
      @quote = @project.pricing_quotes.find(params[:id])
      @orders = @quote.artifact_orders.order(created_at: :desc)
      @product = ProductCatalog.fetch(@quote.product_code)
      @product_notice = product_notice
    end

    private

    def set_project
      @project = DeveloperProject.find(params[:developer_project_id])
    end

    def quote_params
      @quote_params ||= params.require(:pricing_quote).permit(:product_code, scope: {})
    end

    def default_scope
      {
        protocol_complexity: "medium",
        evidence_classes: 4,
        source_systems: 2,
        countries: 1,
        relying_parties: 1,
        selective_disclosure: false,
        turnaround_days: 30
      }
    end
  end
end

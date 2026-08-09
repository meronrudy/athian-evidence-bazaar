module Agevidence
  class ArtifactOrdersController < BaseController
    before_action :set_project
    before_action :set_order, only: %i[show checkout assemble]

    def create
      quote = @project.pricing_quotes.find(params.require(:pricing_quote_id))
      order = Commercial::Orders::Create.call(
        @project,
        quote,
        metadata_json: { source: "browser_developer_os", sandbox: true }
      )
      record_campaign_activation { |recorder| recorder.record_artifact_order_created(order) }
      redirect_to agevidence_developer_project_artifact_order_path(@project, order), notice: "Sandbox artifact order created."
    rescue ActiveRecord::RecordInvalid, ActionController::ParameterMissing => e
      redirect_to agevidence_developer_project_path(@project), alert: e.message
    end

    def show
      @product = ProductCatalog.fetch(@order.product_code)
      @product_notice = product_notice
    end

    def checkout
      Commercial::Orders::MarkPaid.call(
        @order,
        reason: "Sandbox checkout authorized",
        metadata: { sandbox: true, via: "browser" }
      )
      redirect_to agevidence_developer_project_artifact_order_path(@project, @order), notice: "Sandbox checkout completed. No payment was collected."
    rescue RuntimeError => e
      redirect_to agevidence_developer_project_artifact_order_path(@project, @order), alert: e.message
    end

    def assemble
      Commercial::Orders::BeginFulfillment.call(@order)
      Commercial::Orders::Fulfill.call(@order)
      record_campaign_activation { |recorder| recorder.record_artifact_assembled(@order.reload) }
      redirect_to agevidence_developer_project_artifact_order_path(@project, @order.reload), notice: "Reliance artifact assembled through ink_receipts."
    rescue RuntimeError, KeyError, InkReceipts::Error => e
      redirect_to agevidence_developer_project_artifact_order_path(@project, @order), alert: e.message
    end

    private

    def set_project
      @project = DeveloperProject.find(params[:developer_project_id])
    end

    def set_order
      @order = @project.artifact_orders.find(params[:id])
    end
  end
end

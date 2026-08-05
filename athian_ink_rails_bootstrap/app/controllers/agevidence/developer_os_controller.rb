module Agevidence
  class DeveloperOsController < BaseController
    def show
      @projects = DeveloperProject.includes(:developer_account, :source_records, :model_runs, :artifact_orders).order(updated_at: :desc).limit(8)
      @products = ProductCatalog.all
      @project_4030_events = Dir[Rails.root.join("../examples/integrations/project_4030_beef/[0-9][0-9]-*.json")].map { |path| File.basename(path) }.sort
      @inbox_counts = {
        events: IntegrationEvent.count,
        projections: EvidenceProjection.count,
        outbox: ReceiptOutbox.count,
        deliveries: IntegrationDelivery.count
      }
      @product_notice = product_notice
    end

    def openapi
      send_file Rails.root.join("../docs/openapi/agevidence.v1.yaml"), type: "application/yaml", disposition: "inline"
    end
  end
end

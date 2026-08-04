module Agevidence
  class RevenueModelsController < BaseController
    def show
      @projection = RevenueProjection.from_config
      @product_notice = product_notice
      @reliance_events = RelianceEvent.count
      @engagements = ArtifactEngagement.order(created_at: :desc)
    end
  end
end

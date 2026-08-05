module Integrations
  class SourcesController < ApplicationController
    def index
      @sources = IntegrationSource.order(:key)
    end

    def show
      @source = IntegrationSource.find(params[:id])
      @events = @source.integration_events.order(received_at: :desc).limit(25)
      @webhook_endpoints = @source.integration_webhook_endpoints.order(:id)
    end
  end
end

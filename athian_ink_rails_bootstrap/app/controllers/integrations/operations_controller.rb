module Integrations
  class OperationsController < ApplicationController
    def index
      @operations = IntegrationOperation.includes(:integration_event)
                                        .order(created_at: :desc)
                                        .limit(100)
    end

    def show
      @operation = IntegrationOperation.includes(integration_event: :integration_source).find(params[:id])
    end
  end
end

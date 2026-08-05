module V1
  module Campaign
    module Connectors
      class SalesforceEventsController < BaseController
        def create
          result = ::Campaign::SalesforceEventIngestor.new(payload: params.permit!.to_h).call
          render json: result, status: :accepted
        rescue KeyError, RuntimeError, ActiveRecord::RecordInvalid => e
          render_error("CAMPAIGN_SALESFORCE_EVENT_INVALID", status: :unprocessable_entity, message: e.message)
        end
      end
    end
  end
end

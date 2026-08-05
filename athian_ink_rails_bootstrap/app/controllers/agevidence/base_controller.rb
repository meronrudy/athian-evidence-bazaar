module Agevidence
  class BaseController < ApplicationController
    private

    def products
      ProductCatalog.all
    end

    def product_notice
      ProductCatalog.notice
    end

    def campaign_activation_recorder
      Campaign::ActivationRecorder.new(
        campaign_account_id: params[:campaign_account_id].presence || request.headers[Campaign::ActivationRecorder::HEADER_ACCOUNT].presence,
        activation_id: params[:activation_id].presence || request.headers[Campaign::ActivationRecorder::HEADER_ACTIVATION].presence,
        repository_sha: params[:repository_sha].presence || request.headers[Campaign::ActivationRecorder::HEADER_REPOSITORY_SHA].presence,
        sdk_version: request.headers[Campaign::ActivationRecorder::HEADER_SDK_VERSION].presence
      )
    end

    def record_campaign_activation
      yield campaign_activation_recorder
    rescue StandardError
      nil
    end
  end
end

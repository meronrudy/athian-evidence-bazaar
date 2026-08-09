class Developer::DashboardController < ApplicationController
  def index
    @api_keys = ApiKey.all
    @api_logs = ApiLog.all
    @webhooks = Webhook.all
    @schemas = Schema.all
  end
end
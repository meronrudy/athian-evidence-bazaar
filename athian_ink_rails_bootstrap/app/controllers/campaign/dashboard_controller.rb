module Campaign
  class DashboardController < BaseController
    def show
      @snapshot = Campaign::DashboardSnapshot.new.call
    end
  end
end

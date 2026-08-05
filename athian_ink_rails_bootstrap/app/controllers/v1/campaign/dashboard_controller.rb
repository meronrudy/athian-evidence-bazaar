module V1
  module Campaign
    class DashboardController < BaseController
      def show
        snapshot = ::Campaign::DashboardSnapshot.new.call
        render json: {
          counts: snapshot.fetch(:counts),
          phase10: snapshot.fetch(:phase10),
          recent_accounts: snapshot.fetch(:recent_accounts).map { |account| account_payload(account) },
          recent_activations: snapshot.fetch(:recent_activations).map { |activation| activation_payload(activation) },
          recent_qualifications: snapshot.fetch(:recent_qualifications).map { |qualification| qualification_payload(qualification) },
          recent_handoffs: snapshot.fetch(:recent_handoffs).map { |handoff| handoff_payload(handoff) },
          authority_boundary: "Dashboard attribution is campaign state only, not evidence approval or revenue recognition."
        }
      end
    end
  end
end

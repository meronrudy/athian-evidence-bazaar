module Campaign
  class ActivationPath < ApplicationRecord
    include MetadataBoundary

    PATH_TYPES = %w[
      customer_quickstart
      developer_quickstart
      python_sdk
      cli_project_4030
      source_record_browser
      source_record_api
      event_inbox
      artifact_verification
      webhook_integration
    ].freeze

    STATUSES = %w[invited started completed failed ignored].freeze

    belongs_to :campaign_account, class_name: "Campaign::Account"

    before_validation :assign_external_id, on: :create

    validates :external_id, :path_type, :status, presence: true
    validates :external_id, uniqueness: true
    validates :path_type, inclusion: { in: PATH_TYPES }
    validates :status, inclusion: { in: STATUSES }
    validates :repository_sha, format: { with: /\A[a-f0-9]{7,40}\z/ }, allow_blank: true
    validates :support_minutes, numericality: { greater_than_or_equal_to: 0 }
    validates_campaign_metadata :metadata_json

    def start!(occurred_at: Time.current)
      update!(status: "started", started_at: started_at || occurred_at)
    end

    def complete!(occurred_at: Time.current)
      update!(status: "completed", started_at: started_at || occurred_at, completed_at: occurred_at, failed_at: nil, failure_code: nil)
    end

    def fail!(code:, occurred_at: Time.current)
      update!(status: "failed", failed_at: occurred_at, failure_code: code)
    end

    private

    def assign_external_id
      self.external_id ||= "act_#{SecureRandom.alphanumeric(20).downcase}"
    end
  end
end

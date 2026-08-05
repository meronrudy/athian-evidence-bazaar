module Campaign
  class ConnectorOutbox < ApplicationRecord
    include MetadataBoundary

    DESTINATIONS = %w[salesforce apollo].freeze
    STATUSES = %w[pending delivered retrying failed dead_letter].freeze

    validates :destination, :event_type, :aggregate_type, :idempotency_key, :status, presence: true
    validates :destination, inclusion: { in: DESTINATIONS }
    validates :status, inclusion: { in: STATUSES }
    validates :idempotency_key, uniqueness: true
    validates :attempt_count, numericality: { greater_than_or_equal_to: 0 }
    validates_campaign_metadata :payload_json

    scope :deliverable, -> { where(status: %w[pending retrying]).where("next_attempt_at IS NULL OR next_attempt_at <= ?", Time.current) }

    def aggregate
      aggregate_type.safe_constantize&.find_by(id: aggregate_id)
    end

    def delivered?
      status == "delivered"
    end

    def mark_delivered!
      update!(status: "delivered", delivered_at: Time.current, last_error: nil)
    end

    def retry_later!(error, delay: 5.minutes)
      update!(
        status: "retrying",
        attempt_count: attempt_count + 1,
        next_attempt_at: Time.current + delay,
        last_error: error.to_s.truncate(2000)
      )
    end

    def dead_letter!(error)
      update!(
        status: "dead_letter",
        attempt_count: attempt_count + 1,
        next_attempt_at: nil,
        last_error: error.to_s.truncate(2000)
      )
    end
  end
end

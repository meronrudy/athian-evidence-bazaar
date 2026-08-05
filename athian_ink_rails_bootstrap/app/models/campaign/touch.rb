module Campaign
  class Touch < ApplicationRecord
    include MetadataBoundary

    TOUCH_TYPES = %w[
      publication_sent
      guide_sent
      repository_sent
      quickstart_started
      quickstart_completed
      sdk_installed_reported
      cli_replay_completed
      technical_question_received
      sample_payload_received
      artifact_review_requested
      proposal_requested
      unsubscribe_received
      target_account.discovered
      target_account.enriched
      target_contact.discovered
      target_contact.enriched
      outreach.sent
      outreach.replied
      contact.invalid
      contact.unsubscribed
    ].freeze

    belongs_to :campaign_account, class_name: "Campaign::Account"
    belongs_to :campaign_contact_ref, class_name: "Campaign::ContactRef", optional: true

    validates :touch_type, :source_system, :occurred_at, presence: true
    validates :touch_type, inclusion: { in: TOUCH_TYPES }
    validates :repository_sha, format: { with: /\A[a-f0-9]{7,40}\z/ }, allow_blank: true
    validates_campaign_metadata :metadata_json
  end
end

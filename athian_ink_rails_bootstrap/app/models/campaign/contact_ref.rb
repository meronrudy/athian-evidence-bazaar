module Campaign
  class ContactRef < ApplicationRecord
    include MetadataBoundary

    CONTACTABILITY_STATUSES = %w[unknown contactable invalid unsubscribed suppressed bounced].freeze

    belongs_to :campaign_account, class_name: "Campaign::Account"
    has_many :touches, class_name: "Campaign::Touch", foreign_key: :campaign_contact_ref_id, dependent: :nullify

    before_validation :assign_external_id, on: :create
    before_validation :normalize_fields

    validates :external_id, :contactability_status, presence: true
    validates :external_id, uniqueness: { scope: :campaign_account_id }
    validates :salesforce_contact_id, uniqueness: true, allow_blank: true
    validates :apollo_person_id, uniqueness: true, allow_blank: true
    validates :contactability_status, inclusion: { in: CONTACTABILITY_STATUSES }
    validates :email_domain, format: { with: /\A[a-z0-9.-]+\.[a-z]{2,}\z/ }, allow_blank: true
    validates_campaign_metadata :metadata_json

    def unsubscribed?
      contactability_status == "unsubscribed"
    end

    private

    def assign_external_id
      self.external_id ||= "contact_#{SecureRandom.alphanumeric(20).downcase}"
    end

    def normalize_fields
      self.email_domain = email_domain.to_s.downcase.delete_prefix("@").presence
      self.salesforce_contact_id = salesforce_contact_id.to_s.strip.presence
      self.apollo_person_id = apollo_person_id.to_s.strip.presence
    end
  end
end

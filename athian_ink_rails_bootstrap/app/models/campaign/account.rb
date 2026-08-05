module Campaign
  class Account < ApplicationRecord
    include MetadataBoundary

    STATUSES = %w[
      identified
      researched
      approved_for_outreach
      activation_invited
      developer_activated
      evidence_qualified
      reliance_qualified
      commercially_qualified
      handed_to_salesforce
      contracted
      active_customer
      paused
      disqualified
      archived
    ].freeze

    QUALIFICATION_LEVELS = %w[
      unqualified
      market_qualified
      developer_activated
      evidence_qualified
      reliance_qualified
      commercially_qualified
    ].freeze

    STATUS_RANK = STATUSES.each_with_index.to_h.freeze
    QUALIFICATION_RANK = QUALIFICATION_LEVELS.each_with_index.to_h.freeze

    belongs_to :developer_account, class_name: "Agevidence::DeveloperAccount", optional: true
    has_many :contact_refs, class_name: "Campaign::ContactRef", foreign_key: :campaign_account_id, dependent: :destroy
    has_many :activation_paths, class_name: "Campaign::ActivationPath", foreign_key: :campaign_account_id, dependent: :destroy
    has_many :touches, class_name: "Campaign::Touch", foreign_key: :campaign_account_id, dependent: :destroy
    has_many :technical_qualifications, class_name: "Campaign::TechnicalQualification", foreign_key: :campaign_account_id, dependent: :destroy
    has_many :commercial_handoffs, class_name: "Campaign::CommercialHandoff", foreign_key: :campaign_account_id, dependent: :destroy
    has_many :capability_attributions, class_name: "Campaign::CapabilityAttribution", foreign_key: :campaign_account_id, dependent: :destroy

    before_validation :assign_external_id, on: :create
    before_validation :normalize_identity

    validates :external_id, :name, :country_code, :status, :qualification_level, presence: true
    validates :external_id, uniqueness: true
    validates :domain, uniqueness: true, allow_blank: true
    validates :salesforce_account_id, uniqueness: true, allow_blank: true
    validates :apollo_account_id, uniqueness: true, allow_blank: true
    validates :country_code, format: { with: /\A[A-Z]{2}\z/, message: "must be a two-character country code" }
    validates :status, inclusion: { in: STATUSES }
    validates :qualification_level, inclusion: { in: QUALIFICATION_LEVELS }
    validates :priority_score, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
    validates :capital_raised_cents, numericality: { greater_than_or_equal_to: 0 }
    validates_campaign_metadata :metadata_json

    def current_technical_qualification
      technical_qualifications.order(created_at: :desc).first
    end

    def current_commercial_handoff
      commercial_handoffs.order(created_at: :desc).first
    end

    def sync_qualification!(level)
      return unless QUALIFICATION_LEVELS.include?(level)

      update!(
        qualification_level: higher_qualification(level),
        status: higher_status(status_for_qualification(level))
      )
    end

    def advance_status!(candidate_status)
      return unless STATUSES.include?(candidate_status)

      update!(status: higher_status(candidate_status))
    end

    private

    def assign_external_id
      self.external_id ||= "camp_#{SecureRandom.alphanumeric(20).downcase}"
    end

    def normalize_identity
      self.country_code = country_code.to_s.upcase.presence
      self.domain = domain.to_s.downcase.strip.presence
      self.salesforce_account_id = salesforce_account_id.to_s.strip.presence
      self.apollo_account_id = apollo_account_id.to_s.strip.presence
      self.authoritative_system = authoritative_system.to_s.strip.presence
    end

    def status_for_qualification(level)
      case level
      when "developer_activated" then "developer_activated"
      when "evidence_qualified" then "evidence_qualified"
      when "reliance_qualified" then "reliance_qualified"
      when "commercially_qualified" then "commercially_qualified"
      else status
      end
    end

    def higher_qualification(candidate)
      QUALIFICATION_RANK.fetch(candidate) > QUALIFICATION_RANK.fetch(qualification_level) ? candidate : qualification_level
    end

    def higher_status(candidate)
      STATUS_RANK.fetch(candidate) > STATUS_RANK.fetch(status) ? candidate : status
    end
  end
end

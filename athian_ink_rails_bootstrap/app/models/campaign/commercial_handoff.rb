module Campaign
  class CommercialHandoff < ApplicationRecord
    include MetadataBoundary

    STATUSES = %w[ready queued sent accepted contracted cash_recorded closed failed canceled].freeze

    belongs_to :campaign_account, class_name: "Campaign::Account"
    belongs_to :campaign_technical_qualification, class_name: "Campaign::TechnicalQualification"
    has_many :capability_attributions, class_name: "Campaign::CapabilityAttribution", foreign_key: :campaign_commercial_handoff_id, dependent: :nullify

    before_validation :assign_external_id, on: :create
    before_validation :normalize_connector_ids

    validates :external_id, :product_code, :status, :scope_digest, :currency, presence: true
    validates :external_id, uniqueness: true
    validates :salesforce_opportunity_id, uniqueness: true, allow_blank: true
    validates :salesforce_proposal_id, :contract_reference, :invoice_reference, :cash_collection_reference,
              uniqueness: true,
              allow_blank: true
    validates :status, inclusion: { in: STATUSES }
    validates :scope_digest, format: { with: /\Asha256:[a-f0-9]{64}\z/ }
    validates :proposal_terms_digest, :contract_terms_digest,
              format: { with: /\Asha256:[a-f0-9]{64}\z/ },
              allow_blank: true
    validates :planning_value_cents, :contracted_value_cents, :cash_collected_cents, numericality: { greater_than_or_equal_to: 0 }
    validates_campaign_metadata :scope_json, :metadata_json

    def contracted?
      contracted_at.present?
    end

    def cash_recorded?
      cash_recorded_at.present?
    end

    private

    def assign_external_id
      self.external_id ||= "handoff_#{SecureRandom.alphanumeric(20).downcase}"
    end

    def normalize_connector_ids
      self.salesforce_opportunity_id = salesforce_opportunity_id.to_s.strip.presence
      self.salesforce_proposal_id = salesforce_proposal_id.to_s.strip.presence
      self.proposal_reference = proposal_reference.to_s.strip.presence
      self.proposal_terms_digest = proposal_terms_digest.to_s.strip.presence
      self.contract_reference = contract_reference.to_s.strip.presence
      self.contract_terms_digest = contract_terms_digest.to_s.strip.presence
      self.invoice_reference = invoice_reference.to_s.strip.presence
      self.cash_collection_reference = cash_collection_reference.to_s.strip.presence
      self.revenue_system = revenue_system.to_s.strip.presence
    end
  end
end

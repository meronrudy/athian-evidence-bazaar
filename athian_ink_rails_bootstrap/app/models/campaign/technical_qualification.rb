module Campaign
  class TechnicalQualification < ApplicationRecord
    include MetadataBoundary

    STATUSES = %w[draft evaluated qualified rejected superseded].freeze

    attr_readonly :campaign_account_id,
                  :developer_project_id,
                  :external_id,
                  :status,
                  :qualification_level,
                  :authoritative_system_confirmed,
                  :supported_event_count,
                  :required_event_count,
                  :evidence_gap_count,
                  :unreviewed_candidate_count,
                  :country_code,
                  :country_adapter_identifier,
                  :named_obligation_code,
                  :named_relying_party_type,
                  :qualification_reason,
                  :qualified_at,
                  :country_adapter_readiness,
                  :institution_profile,
                  :obligation_profile,
                  :local_evidence_gap_count,
                  :cross_country_portability_result,
                  :snapshot_json

    belongs_to :campaign_account, class_name: "Campaign::Account"
    belongs_to :developer_project, class_name: "Agevidence::DeveloperProject", optional: true
    has_many :commercial_handoffs, class_name: "Campaign::CommercialHandoff", foreign_key: :campaign_technical_qualification_id, dependent: :restrict_with_error

    before_validation :assign_external_id, on: :create
    before_validation :normalize_country_code

    validates :external_id, :status, :qualification_level, presence: true
    validates :external_id, uniqueness: true
    validates :status, inclusion: { in: STATUSES }
    validates :qualification_level, inclusion: { in: Campaign::Account::QUALIFICATION_LEVELS }
    validates :country_code, format: { with: /\A[A-Z]{2}\z/ }, allow_blank: true
    validates :supported_event_count, :required_event_count, :evidence_gap_count, :unreviewed_candidate_count, :local_evidence_gap_count,
              numericality: { greater_than_or_equal_to: 0 }
    validates_campaign_metadata :snapshot_json

    def qualified?
      status == "qualified" || qualification_level.in?(%w[developer_activated evidence_qualified reliance_qualified commercially_qualified])
    end

    private

    def assign_external_id
      self.external_id ||= "tq_#{SecureRandom.alphanumeric(20).downcase}"
    end

    def normalize_country_code
      self.country_code = country_code.to_s.upcase.presence
    end
  end
end

class EvidenceBundle < ApplicationRecord
  BUNDLE_TYPES = InkReceipts::BUNDLE_TYPES.keys.freeze
  STATUSES = %w[generated downloaded verified failed].freeze
  RELIANCE_STATUSES = %w[not_relied_on accepted relied_on rejected needs_more_evidence].freeze

  belongs_to :avsa
  belongs_to :acceptance_receipt, class_name: "Receipt", optional: true
  belongs_to :agevidence_country_adapter, class_name: "Agevidence::CountryAdapter", foreign_key: :country_adapter_id, optional: true
  belongs_to :agevidence_country_claim_policy, class_name: "Agevidence::CountryClaimPolicy", foreign_key: :country_claim_policy_id, optional: true
  belongs_to :agevidence_country_verification_profile, class_name: "Agevidence::CountryVerificationProfile", foreign_key: :country_verification_profile_id, optional: true
  belongs_to :agevidence_country_data_policy, class_name: "Agevidence::CountryDataPolicy", foreign_key: :country_data_policy_id, optional: true
  belongs_to :agevidence_country_determination, class_name: "Agevidence::CountryDetermination", foreign_key: :country_determination_id, optional: true
  belongs_to :country_adapter, class_name: "Agevidence::CountryAdapter", optional: true
  belongs_to :country_claim_policy, class_name: "Agevidence::CountryClaimPolicy", optional: true
  belongs_to :country_verification_profile, class_name: "Agevidence::CountryVerificationProfile", optional: true
  belongs_to :country_data_policy, class_name: "Agevidence::CountryDataPolicy", optional: true
  belongs_to :country_determination, class_name: "Agevidence::CountryDetermination", optional: true
  has_many :agevidence_reliance_events, class_name: "Agevidence::RelianceEvent", dependent: :restrict_with_error

  validates :bundle_type, :name, :generated_at, :artifact_filename, presence: true
  validates :bundle_type, inclusion: { in: BUNDLE_TYPES }
  validates :status, inclusion: { in: STATUSES }
  validates :reliance_status, inclusion: { in: RELIANCE_STATUSES }

  def evidence_bundle_digest
    manifest_value("artifact_digest").presence ||
      manifest_value("bundle_digest").presence ||
      manifest_value("verification_report").try(:[], "bundle_digest").presence ||
      artifact_filename
  end

  private

  def manifest_value(key)
    manifest[key] || manifest[key.to_sym]
  end
end

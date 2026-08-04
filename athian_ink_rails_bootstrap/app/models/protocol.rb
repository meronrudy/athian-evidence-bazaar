class Protocol < ApplicationRecord
  STATUSES = %w[draft active annual_review retired].freeze

  has_many :avsas, dependent: :restrict_with_error

  validates :code, :name, :version, :governance_version, presence: true
  validates :code, uniqueness: true
  validates :status, inclusion: { in: STATUSES }

  scope :active, -> { where(status: "active") }

  def display_name
    "#{code} v#{version}"
  end

  def protocol_digest
    InkReceipts.issue(
      payload: {
        code: code,
        version: version,
        governance_version: governance_version,
        effective_on: effective_on,
        retired_on: retired_on
      },
      issuer: "Athian Governance",
      receipt_type: "protocol_commitment",
      schema: "athian.protocol_commitment.v1"
    ).fetch(:body_digest)
  end
end

class User < ApplicationRecord
  ROLES = %w[
    owner
    administrator
    developer
    project_manager
    evidence_reviewer
    billing_manager
    auditor
    viewer
  ].freeze

  has_many :organization_memberships, dependent: :destroy
  has_many :organizations, through: :organization_memberships
  has_many :invitations, foreign_key: :invited_by_id, dependent: :nullify

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role, inclusion: { in: ROLES }, allow_nil: true

  def self.current
    Current.user
  end

  def owner?
    organization_memberships.any? { |m| m.role == "owner" }
  end
end

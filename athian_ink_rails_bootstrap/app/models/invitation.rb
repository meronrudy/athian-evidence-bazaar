class Invitation < ApplicationRecord
  belongs_to :organization
  belongs_to :invited_by, class_name: "User", optional: true

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role, presence: true, inclusion: { in: User::ROLES }
  validates :token, presence: true, uniqueness: true

  before_validation :generate_token, on: :create

  def expired?
    expires_at.present? && expires_at < Time.current
  end

  def accept!(user)
    return false if expired?

    OrganizationMembership.create!(
      organization: organization,
      user: user,
      role: role
    )
    destroy!
    true
  end

  private

  def generate_token
    self.token ||= SecureRandom.urlsafe_base64(32)
    self.expires_at ||= 7.days.from_now
  end
end

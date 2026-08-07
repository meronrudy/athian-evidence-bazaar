class OrganizationMembership < ApplicationRecord
  ROLES = User::ROLES

  belongs_to :organization
  belongs_to :user

  validates :role, presence: true, inclusion: { in: ROLES }
  validates :user_id, uniqueness: { scope: :organization_id }

  after_create :ensure_owner_role_if_first

  private

  def ensure_owner_role_if_first
    if organization.organization_memberships.count == 1
      update!(role: "owner")
    end
  end
end

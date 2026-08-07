class Current < ActiveSupport::CurrentAttributes
  attribute :user
  attribute :organization
  attribute :membership
  attribute :request_id
  attribute :api_credential

  # Set from controller or API context
  def self.set_from_request(request, credential = nil)
    self.request_id = request.request_id
    self.api_credential = credential

    if credential
      self.organization = credential.organization
      self.user = credential.user
      self.membership = credential.organization_membership
    end
  end

  def self.organization=(org)
    super
    # Auto-set membership if user is present
    if user && org
      self.membership = org.organization_memberships.find_by(user: user)
    end
  end
end

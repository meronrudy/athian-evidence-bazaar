class Verification < ApplicationRecord
  belongs_to :receipt, optional: true

  validates :verification_method, presence: true
  validates :integrity_hash, presence: true

  scope :verified, -> { where(verified: true) }
  scope :failed, -> { where(verified: false) }

  def self.find_by_url(url)
    # Find verification by source URL
    where("verification_data->>'source_url' = ?", url).first
  end

  def verified?
    verified == true
  end
end
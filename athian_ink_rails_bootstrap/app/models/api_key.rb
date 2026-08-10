class ApiKey < ApplicationRecord
  belongs_to :user
  belongs_to :project, optional: true

  before_validation :generate_key, on: :create

  scope :active, -> { where(revoked_at: nil) }
  scope :revoked, -> { where.not(revoked_at: nil) }

  validates :name, presence: true
  validates :key, presence: true, uniqueness: true

  def revoke!
    update!(revoked_at: Time.current)
  end

  def active?
    revoked_at.nil?
  end

  def masked_key
    "#{key[0..7]}...#{key[-4..-1]}"
  end

  private

  def generate_key
    self.key ||= SecureRandom.hex(32)
  end
end

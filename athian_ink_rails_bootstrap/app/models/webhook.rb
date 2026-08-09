class Webhook < ApplicationRecord
  belongs_to :project, optional: true

  scope :active, -> { where(active: true) }
  scope :by_event, ->(event) { where(event: event) }

  validates :url, presence: true
  validates :event, presence: true
  validates :active, inclusion: { in: [true, false] }

  def payload
    # Placeholder for payload template or configuration
  end
end
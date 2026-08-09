class ApiLog < ApplicationRecord
  belongs_to :api_key, optional: true

  scope :recent, -> { order(created_at: :desc) }
  scope :by_endpoint, ->(endpoint) { where(endpoint: endpoint) }
  scope :by_status, ->(status) { where(status: status) }
  scope :errors, -> { where('status >= ?', 400) }

  validates :endpoint, presence: true
  validates :method, presence: true
  validates :status, presence: true, numericality: { only_integer: true }
  validates :request_id, presence: true

  def success?
    status.between?(200, 299)
  end

  def error?
    status >= 400
  end

  def duration_ms
    (duration * 1000).round(2) if duration
  end
end
class Verification < ApplicationRecord
  # Scopes
  scope :verified, -> { where(status: 'verified') }
  scope :failed, -> { where(status: 'failed') }
  scope :pending, -> { where(status: 'pending') }

  # Validations
  validates :receipt_id, presence: true, unless: -> { url.present? || json_bundle.present? }
  validates :url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }, allow_blank: true

  # Class methods
  def self.find_by_url(url)
    where(url: url).first
  end
  def self.find_by_receipt_id(receipt_id)
    where(receipt_id: receipt_id).first
  end
  def self.create_from_json_bundle(json_data)
    receipt_id = json_data.dig('receipt', 'id') || json_data.dig('evidence', 'receipt_id')
    url = json_data.dig('evidence', 'url') || json_data.dig('source', 'url')
    create!(
      receipt_id: receipt_id,
      url: url,
      json_bundle: json_data.to_json,
      status: 'pending'
    )
  end

  # Instance methods
  def verified?
    status == 'verified'
  end
  def failed?
    status == 'failed'
  end
  def pending?
    status == 'pending'
  end
  def mark_verified!(details = {})
    update!(status: 'verified', verified_at: Time.current, details: details)
  end
  def mark_failed!(error_message)
    update!(status: 'failed', error_message: error_message, verified_at: Time.current)
  end
  def process_json_bundle(json_data)
    self.json_bundle = json_data.to_json
    self.receipt_id ||= json_data.dig('receipt', 'id') || json_data.dig('evidence', 'receipt_id')
    self.url ||= json_data.dig('evidence', 'url') || json_data.dig('source', 'url')
    if receipt_id.blank? && url.blank?
      errors.add(:base, "JSON bundle must contain either a receipt ID or evidence URL")
    end
  end
  def verify_receipt_integrity(receipt_id)
    if receipt_id.present? && receipt_id.match?(/\Aagv-[a-z0-9]{8,}\z/i)
      mark_verified!(receipt_id: receipt_id, verified_at: Time.current)
      return true
    else
      mark_failed!("Invalid receipt ID format")
      return false
    end
  end
  def verify_url_integrity(url)
    if url.present? && url.match?(/\Ahttps?:\/\//)
      mark_verified!(url: url, verified_at: Time.current)
      return true
    else
      mark_failed!("Invalid URL format")
      return false
    end
  end
end
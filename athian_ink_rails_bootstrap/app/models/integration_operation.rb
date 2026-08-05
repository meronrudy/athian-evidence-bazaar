class IntegrationOperation < ApplicationRecord
  STATUSES = %w[pending running succeeded failed retrying dead_letter].freeze

  belongs_to :integration_event

  validates :external_id, :operation_type, :status, :idempotency_key, presence: true
  validates :external_id, :idempotency_key, uniqueness: true
  validates :status, inclusion: { in: STATUSES }

  before_validation :assign_external_id, on: :create

  def succeed!(result = {})
    update!(status: "succeeded", completed_at: Time.current, result_json: result)
  end

  def fail!(code:, message:)
    update!(status: "failed", completed_at: Time.current, error_code: code, error_message: message)
  end

  private

  def assign_external_id
    self.external_id ||= "op_#{SecureRandom.alphanumeric(26).downcase}"
  end
end

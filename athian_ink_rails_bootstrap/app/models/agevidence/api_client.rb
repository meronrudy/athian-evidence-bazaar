module Agevidence
  class ApiClient < ApplicationRecord
    STATUSES = %w[active suspended revoked].freeze
    DEFAULT_SCOPES = %w[products:read evidence_runs:write evidence_runs:read artifacts:write artifacts:read usage:write usage:read].freeze

    belongs_to :developer_account, class_name: "Agevidence::DeveloperAccount"
    has_many :usage_events, class_name: "Agevidence::UsageEvent", dependent: :nullify

    has_secure_password :token, validations: false

    serialize :scopes, coder: JSON

    validates :name, :token_prefix, :token_digest, presence: true
    validates :token_prefix, uniqueness: true
    validates :status, inclusion: { in: STATUSES }
    validates :rate_limit_per_minute, numericality: { greater_than: 0 }

    scope :active, -> { where(status: "active") }

    def self.issue!(developer_account:, name:, scopes: DEFAULT_SCOPES, expires_at: nil)
      raw_token = "agev_live_#{SecureRandom.hex(24)}"
      client = create!(
        developer_account: developer_account,
        name: name,
        token: raw_token,
        token_prefix: raw_token.first(18),
        scopes: Array(scopes).map(&:to_s).uniq,
        expires_at: expires_at
      )
      [client, raw_token]
    end

    def allows?(scope)
      Array(scopes).include?(scope.to_s)
    end

    def usable?
      status == "active" && (expires_at.nil? || expires_at.future?)
    end

    def touch_usage!
      update_column(:last_used_at, Time.current)
    end
  end
end

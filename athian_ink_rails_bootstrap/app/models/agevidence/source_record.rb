module Agevidence
  class SourceRecord < ApplicationRecord
    STATUSES = %w[referenced projected receipt_requested receipt_verified superseded rejected].freeze
    DISCLOSURE_STATUSES = %w[public selective restricted withheld].freeze

    belongs_to :developer_project, class_name: "Agevidence::DeveloperProject"
    belongs_to :source_event, class_name: "IntegrationEvent", optional: true
    belongs_to :evidence_projection, optional: true
    belongs_to :receipt, optional: true

    validates :document_id, :evidence_type, :evidence_class, :controlled_uri, :commitment, :status, :disclosure_status, presence: true
    validates :document_id, uniqueness: { scope: :developer_project_id }
    validates :status, inclusion: { in: STATUSES }
    validates :disclosure_status, inclusion: { in: DISCLOSURE_STATUSES }
    validates :commitment, format: { with: /\A[a-z0-9_.-]+:.+\z/, message: "must include an algorithm or commitment namespace" }
    validate :controlled_uri_is_reference

    def projected?
      %w[projected receipt_requested receipt_verified].include?(status)
    end

    private

    def controlled_uri_is_reference
      return if controlled_uri.to_s.start_with?("evidence://", "s3://", "https://", "http://")

      errors.add(:controlled_uri, "must be a controlled reference URI")
    end
  end
end

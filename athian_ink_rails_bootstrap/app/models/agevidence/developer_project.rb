module Agevidence
  class DeveloperProject < ApplicationRecord
    PROJECT_TYPES = %w[intervention measurement_product data_product platform].freeze
    PROTOCOL_STATUSES = %w[mapping review_required aligned blocked].freeze
    INTEGRATION_STATUSES = %w[not_started source_registered model_ready receipt_ready artifact_ready relied_on].freeze

    belongs_to :developer_account, class_name: "Agevidence::DeveloperAccount"
    belongs_to :protocol, optional: true
    belongs_to :avsa, optional: true
    has_many :model_runs, class_name: "Agevidence::ModelRun", dependent: :destroy
    has_many :artifact_engagements, class_name: "Agevidence::ArtifactEngagement", dependent: :destroy

    validates :name, :project_type, :protocol_status, :integration_status, presence: true
    validates :project_type, inclusion: { in: PROJECT_TYPES }
    validates :protocol_status, inclusion: { in: PROTOCOL_STATUSES }
    validates :integration_status, inclusion: { in: INTEGRATION_STATUSES }

    def source_documents
      return [] unless avsa

      avsa.receipts.includes(:evidence_items).flat_map do |receipt|
        receipt.evidence_items.map do |item|
          document_id = item.metadata.fetch("document_id", item.name.to_s.parameterize)
          {
            document_id: document_id,
            commitment: item.commitment,
            controlled_uri: "evidence://#{document_id}",
            receipt_id: receipt.id,
            evidence_item_id: item.id
          }
        end
      end
    end
  end
end

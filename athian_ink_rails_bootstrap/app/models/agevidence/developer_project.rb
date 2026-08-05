module Agevidence
  class DeveloperProject < ApplicationRecord
    PROJECT_TYPES = %w[intervention measurement_product data_product platform].freeze
    PROTOCOL_STATUSES = %w[mapping review_required aligned blocked].freeze
    INTEGRATION_STATUSES = %w[not_started source_registered model_ready receipt_ready artifact_ready relied_on].freeze

    belongs_to :developer_account, class_name: "Agevidence::DeveloperAccount"
    belongs_to :country_program, class_name: "Agevidence::CountryProgram", optional: true
    belongs_to :primary_country_program, class_name: "Agevidence::CountryProgram", optional: true
    belongs_to :protocol, optional: true
    belongs_to :avsa, optional: true
    has_many :model_runs, class_name: "Agevidence::ModelRun", dependent: :destroy
    has_many :artifact_engagements, class_name: "Agevidence::ArtifactEngagement", dependent: :destroy
    has_many :country_determinations, class_name: "Agevidence::CountryDetermination", dependent: :destroy
    has_many :source_records, class_name: "Agevidence::SourceRecord", dependent: :destroy
    has_many :pricing_quotes, class_name: "Agevidence::PricingQuote", dependent: :destroy
    has_many :artifact_orders, class_name: "Agevidence::ArtifactOrder", dependent: :destroy

    validates :name, :project_type, :protocol_status, :integration_status, presence: true
    validates :project_type, inclusion: { in: PROJECT_TYPES }
    validates :protocol_status, inclusion: { in: PROTOCOL_STATUSES }
    validates :integration_status, inclusion: { in: INTEGRATION_STATUSES }

    def source_documents
      source_record_documents + avsa_evidence_documents
    end

    def evidence_graph_root
      avsa&.root_digest.presence || avsa&.portable_reference || "project-#{id}"
    end

    private

    def source_record_documents
      source_records.order(:document_id).map do |record|
        {
          document_id: record.document_id,
          commitment: record.commitment,
          controlled_uri: record.controlled_uri,
          source_record_id: record.id,
          evidence_type: record.evidence_type,
          global_evidence_type: record.metadata_json["global_evidence_type"],
          source_system: record.source_system
        }
      end
    end

    def avsa_evidence_documents
      return [] unless avsa

      avsa.receipts.includes(:evidence_items).flat_map do |receipt|
        receipt.evidence_items.map do |item|
          document_id = item.metadata.fetch("document_id", item.name.to_s.parameterize)
          {
            document_id: document_id,
            commitment: item.commitment,
            controlled_uri: "evidence://#{document_id}",
            receipt_id: receipt.id,
            evidence_item_id: item.id,
            evidence_type: item.evidence_type,
            global_evidence_type: item.metadata["global_evidence_type"]
          }
        end
      end
    end
  end
end

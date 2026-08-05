class ExternalObjectMapping < ApplicationRecord
  INTERNAL_TYPES = {
    "developer_project" => "Agevidence::DeveloperProject",
    "protocol" => "Protocol",
    "country_method_version" => "Agevidence::CountryMethodVersion",
    "model_run" => "Agevidence::ModelRun",
    "avsa" => "Avsa",
    "producer_payment" => "ProducerPayment",
    "evidence_projection" => "EvidenceProjection",
    "evidence_bundle" => "EvidenceBundle"
  }.freeze

  belongs_to :integration_source
  belongs_to :last_integration_event, class_name: "IntegrationEvent", optional: true

  validates :external_object_type,
            :external_object_id,
            :internal_record_type,
            :first_seen_at,
            :last_seen_at,
            presence: true
  validates :internal_record_type, inclusion: { in: INTERNAL_TYPES.values }
  validates :external_object_id,
            uniqueness: {
              scope: %i[integration_source_id external_object_type internal_record_type]
            }

  def internal_record
    return nil if internal_record_id.blank?

    internal_record_type.constantize.find_by(id: internal_record_id)
  end

  def internal_record=(record)
    self.internal_record_type = record.class.name
    self.internal_record_id = record.id
  end
end

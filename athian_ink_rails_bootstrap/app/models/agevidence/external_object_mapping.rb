module Agevidence
  class ExternalObjectMapping < ApplicationRecord
    belongs_to :integration_source, class_name: "Agevidence::IntegrationSource"
    belongs_to :last_integration_event, class_name: "Agevidence::IntegrationEvent", optional: true
    belongs_to :internal_record, polymorphic: true, optional: true

    serialize :projection_payload, coder: JSON

    validates :external_object_type, :external_object_id, presence: true
    validates :external_object_id,
              uniqueness: { scope: %i[integration_source_id external_object_type] }

    def attach!(record)
      update!(internal_record: record)
      record
    end
  end
end

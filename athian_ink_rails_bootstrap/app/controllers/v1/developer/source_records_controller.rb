module V1
  module Developer
    class SourceRecordsController < BaseController
      before_action :set_project

      def index
        render json: {
          project: project_payload(@project),
          source_records: @project.source_records.order(:document_id).map { |record| source_record_payload(record) }
        }
      end

      def create
        record = @project.source_records.create!(source_record_params)
        event = Agevidence::SourceRecordProjection.new(source_record: record).call
        record_campaign_activation { |recorder| recorder.record_source_record_created(record.reload) }
        render json: source_record_payload(record.reload).merge(
          event_id: event.external_event_id,
          operation_id: event.current_operation&.external_id,
          next_step: "Run fixture-backed evidence extraction or submit signed operational events through the inbox."
        ), status: :created
      rescue ActiveRecord::RecordInvalid, KeyError => e
        render_error("SOURCE_RECORD_INVALID", status: :unprocessable_entity, message: e.message)
      end

      private

      def set_project
        @project = find_project!
      end

      def source_record_params
        params.require(:source_record).permit(
          :document_id,
          :evidence_type,
          :evidence_class,
          :source_system,
          :controlled_uri,
          :commitment,
          :disclosure_status,
          :captured_at,
          metadata_json: {}
        )
      end
    end
  end
end

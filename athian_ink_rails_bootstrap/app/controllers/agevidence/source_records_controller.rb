module Agevidence
  class SourceRecordsController < BaseController
    before_action :set_project

    def index
      @source_record = @project.source_records.new(
        evidence_class: "source_record",
        disclosure_status: "restricted",
        source_system: "developer_source_console"
      )
      @source_records = @project.source_records.order(:document_id)
      @operations = @source_records.includes(source_event: :integration_operations).map { |record| record.source_event&.current_operation }.compact
    end

    def create
      @source_record = @project.source_records.create!(source_record_params)
      Agevidence::SourceRecordProjection.new(source_record: @source_record).call
      redirect_to agevidence_developer_project_source_records_path(@project), notice: "Source reference submitted through the append-only inbox."
    rescue ActiveRecord::RecordInvalid => e
      @source_records = @project.source_records.order(:document_id)
      @operations = []
      flash.now[:alert] = e.message
      render :index, status: :unprocessable_entity
    end

    private

    def set_project
      @project = DeveloperProject.find(params[:developer_project_id])
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

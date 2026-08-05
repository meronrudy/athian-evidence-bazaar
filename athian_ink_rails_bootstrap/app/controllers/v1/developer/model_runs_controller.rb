module V1
  module Developer
    class ModelRunsController < BaseController
      before_action :set_project

      def create
        run = Agevidence::ModelRunIngestion.new(
          project: @project,
          model_adapter: requested_adapter
        ).call
        record_campaign_activation { |recorder| recorder.record_model_run_created(run) }
        render json: model_run_payload(run), status: :created
      rescue ActiveRecord::RecordInvalid, KeyError, RuntimeError => e
        render_error("MODEL_RUN_INVALID", status: :unprocessable_entity, message: e.message)
      end

      def show
        run = @project.model_runs.includes(:model_adapter, :evidence_candidates, :evidence_gaps).find(params[:id])
        render json: model_run_payload(run)
      end

      private

      def set_project
        @project = find_project!
      end

      def requested_adapter
        adapter_id = params[:adapter_id].presence || params.dig(:model_run, :adapter_id).presence || "qwen3.5-4b-reference"
        Agevidence::ModelAdapter.find_or_create_by!(adapter_id: adapter_id) do |adapter|
          adapter.base_model_id = adapter_id == "qwen3.5-4b-reference" ? "Qwen/Qwen3.5-4B" : adapter_id
          adapter.provider = "fixture"
          adapter.license = "reference"
          adapter.runtime = "fixture"
          adapter.weights_digest = "fixture:#{adapter_id}:weights"
          adapter.adapter_digest = "fixture:#{adapter_id}:adapter"
          adapter.status = "reference"
        end
      end
    end
  end
end

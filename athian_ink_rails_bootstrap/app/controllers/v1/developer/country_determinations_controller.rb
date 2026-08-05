module V1
  module Developer
    class CountryDeterminationsController < BaseController
      def index
        project = find_project!
        render json: project.country_determinations.includes(:country_adapter, :receipt).order(evaluated_at: :desc).map { |determination| determination_payload(determination) }
      end

      def create
        project = find_project!
        adapter = Agevidence::CountryAdapterCatalog.resolve_adapter!(params.require(:adapter))
        project.update!(country_program: adapter.country_program, primary_country_program: adapter.country_program)
        determination = Agevidence::CountryDeterminationAppender.new(
          project: project,
          country_adapter: adapter,
          institution_profile: institution_profile
        ).call
        render json: determination_payload(determination), status: :created
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound, KeyError, RuntimeError, InkReceipts::Error => e
        render_error("COUNTRY_DETERMINATION_INVALID", status: :unprocessable_entity, message: e.message)
      end

      private

      def institution_profile
        value = params[:institution_profile]
        return nil if value.blank?
        return value.to_unsafe_h if value.respond_to?(:to_unsafe_h)

        value
      end

      def determination_payload(determination)
        {
          id: determination.id,
          project_id: determination.developer_project_id,
          adapter_id: determination.country_adapter.adapter_id,
          country_code: determination.country_adapter.country_code,
          adapter_version: determination.country_adapter.version,
          method_id: determination.country_method_version.method_id,
          method_version: determination.country_method_version.version,
          status: determination.status,
          normalized_result: determination.normalized_result,
          receipt_id: determination.receipt_id,
          result_digest: determination.result_digest,
          supersedes: determination.supersedes_id,
          evaluated_at: determination.evaluated_at&.iso8601
        }
      end
    end
  end
end

module Api
  module V1
    class EvidenceRunsController < BaseController
      before_action -> { require_scope!("evidence_runs:write") }, only: :create
      before_action -> { require_scope!("evidence_runs:read") }, only: :show

      def create
        key = idempotency_key!
        existing_event = Agevidence::UsageEvent.find_by(developer_account: current_developer_account, idempotency_key: key)
        if existing_event&.metadata&.fetch("model_run_id", nil)
          run = Agevidence::ModelRun.find(existing_event.metadata.fetch("model_run_id"))
          return render json: { data: serialize(run) }, status: :ok
        end

        project = current_developer_account.developer_projects.find(run_params.fetch(:developer_project_id))
        adapter = Agevidence::ModelAdapter.find_by!(adapter_id: run_params.fetch(:adapter_id))

        run = nil
        Agevidence::ModelRun.transaction do
          run = Agevidence::ModelRunIngestion.new(project: project, model_adapter: adapter).call
          if ActiveModel::Type::Boolean.new.cast(run_params.fetch(:issue_receipts, true))
            issuer = Agevidence::ReceiptIssuer.new
            issuer.issue_model_execution!(run)
            run.evidence_candidates.find_each { |candidate| issuer.issue_evidence_candidate!(candidate) unless candidate.receipt }
          end
          Agevidence::UsageEvent.create!(
            developer_account: current_developer_account,
            api_client: current_api_client,
            event_type: "evidence_run",
            product_code: current_plan_code,
            quantity: 1,
            unit: "api_operation",
            idempotency_key: key,
            occurred_at: Time.current,
            metadata: { "model_run_id" => run.id, "adapter_id" => adapter.adapter_id }
          )
        end

        render json: { data: serialize(run.reload) }, status: :created
      end

      def show
        run = Agevidence::ModelRun.joins(:developer_project)
                                   .where(agevidence_developer_projects: { developer_account_id: current_developer_account.id })
                                   .find(params[:id])
        render json: { data: serialize(run) }
      end

      private

      def run_params
        params.require(:evidence_run).permit(:developer_project_id, :adapter_id, :issue_receipts)
      end

      def current_plan_code
        current_developer_account.billing_account&.subscriptions&.where(status: %w[trialing active])&.order(created_at: :desc)&.first&.price_book&.product_code || "developer_api_builder"
      end

      def serialize(run)
        {
          id: run.id,
          status: run.status,
          task: run.task,
          developer_project_id: run.developer_project_id,
          adapter_id: run.model_adapter.adapter_id,
          receipt_id: run.receipt_id,
          output_digest: run.output_digest,
          limitations: run.limitations,
          candidates: run.evidence_candidates.map do |candidate|
            {
              id: candidate.id,
              candidate_type: candidate.candidate_type,
              claim_text: candidate.claim_text,
              source_references: candidate.source_references,
              review_status: candidate.review_status,
              receipt_id: candidate.receipt_id
            }
          end,
          gaps: run.evidence_gaps.map do |gap|
            {
              id: gap.id,
              gap_type: gap.gap_type,
              requirement: gap.requirement,
              severity: gap.severity,
              description: gap.description,
              resolution_status: gap.resolution_status
            }
          end,
          created_at: run.created_at,
          completed_at: run.completed_at
        }
      end
    end
  end
end

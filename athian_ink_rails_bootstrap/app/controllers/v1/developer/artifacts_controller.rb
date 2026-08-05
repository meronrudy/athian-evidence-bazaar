module V1
  module Developer
    class ArtifactsController < BaseController
      before_action :set_project

      def create
        order = requested_order || build_order_from_quote
        order.checkout! if ActiveModel::Type::Boolean.new.cast(params[:sandbox_checkout])
        if order.status == "paid"
          Agevidence::ArtifactOrderFulfillment.new(order: order).call
          render json: order_payload(order.reload), status: :created
        else
          render json: order_payload(order).merge(next_step: "POST /v1/artifact-orders/#{order.external_id}/checkout"), status: :accepted
        end
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound, KeyError, RuntimeError => e
        render_error("ARTIFACT_REQUEST_INVALID", status: :unprocessable_entity, message: e.message)
      end

      def show
        render json: order_payload(order_for_artifact)
      end

      def download
        order = order_for_artifact
        render json: {
          artifact_id: "artifact_#{order.evidence_bundle&.id}",
          download_url: order.metadata_json["download_url"],
          verification_command: order.metadata_json["verification_command"],
          note: "This scaffold returns artifact metadata. Production deployments should use short-lived object-storage URLs."
        }
      end

      private

      def set_project
        @project = find_project!
      end

      def requested_order
        return nil if params[:order_id].blank?

        @project.artifact_orders.find_by!(external_id: params[:order_id])
      end

      def build_order_from_quote
        quote = if params[:quote_id].present?
                  @project.pricing_quotes.find_by!(external_id: params[:quote_id])
                else
                  Agevidence::PricingEngine.new(
                    project: @project,
                    product_code: params[:product_code].presence || "verification_readiness_cycle",
                    scope: artifact_scope_param
                  ).quote
                end

        @project.artifact_orders.create!(
          pricing_quote: quote,
          product_code: quote.product_code,
          status: "quoted",
          amount_cents: quote.amount_cents,
          currency: quote.currency,
          metadata_json: { source: "developer_artifacts_api", sandbox: true }
        )
      end

      def artifact_scope_param
        scope = params[:scope]
        return {} if scope.blank?
        return scope.permit!.to_h if scope.respond_to?(:permit!)

        scope.to_h
      end

      def order_for_artifact
        if params[:id].to_s.start_with?("artifact_")
          bundle = @project.artifact_orders.includes(:evidence_bundle).map(&:evidence_bundle).compact.find { |candidate| "artifact_#{candidate.id}" == params[:id] }
          return @project.artifact_orders.find_by!(evidence_bundle: bundle) if bundle
        end

        @project.artifact_orders.find_by!(external_id: params[:id])
      end
    end
  end
end

module V1
  class ArtifactOrdersController < ActionController::API
    def create
      quote = Agevidence::PricingQuote.find_by!(external_id: order_params.require(:quote_id))
      order = Commercial::Orders::Create.call(
        quote.developer_project,
        quote,
        metadata_json: {
          source: "v1_api",
          sandbox: true,
          artifact_scope: order_params[:artifact_scope].presence || {}
        }
      )
      record_campaign_order(order)
      render json: order_payload(order), status: :created
    rescue ActiveRecord::RecordNotFound
      render json: { error: { code: "QUOTE_NOT_FOUND", message: "Quote was not found." } }, status: :not_found
    rescue ActiveRecord::RecordInvalid, ActionController::ParameterMissing => e
      render json: { error: { code: "ARTIFACT_ORDER_INVALID", message: e.message } }, status: :unprocessable_entity
    end

    def show
      render json: order_payload(find_order!)
    end

    def checkout
      order = find_order!
      # Use commercial transition service instead of direct checkout!
      Commercial::Orders::MarkPaid.call(
        order,
        reason: "Sandbox checkout authorized",
        metadata: { sandbox: true, via: "v1_api" }
      )
      render json: order_payload(order.reload)
    rescue RuntimeError => e
      render json: { error: { code: "SANDBOX_CHECKOUT_FAILED", message: e.message } }, status: :unprocessable_entity
    end

    private

    def order_params
      @order_params ||= params.require(:artifact_order).permit(:quote_id, artifact_scope: {})
    end

    def find_order!
      Agevidence::ArtifactOrder.find_by!(external_id: params[:external_id])
    end

    def order_payload(order)
      {
        order_id: order.external_id,
        quote_id: order.pricing_quote.external_id,
        project_id: order.developer_project_id,
        product_code: order.product_code,
        status: order.status,
        currency: order.currency,
        amount: order.amount_cents,
        checkout_url: order.checkout_url,
        checkout_completed_at: order.checkout_completed_at&.iso8601,
        assembled_at: order.assembled_at&.iso8601,
        artifact: artifact_payload(order),
        notice: "Sandbox checkout only. This is not collected, booked, or recognized revenue."
      }
    end

    def artifact_payload(order)
      return nil unless order.evidence_bundle

      {
        artifact_id: "artifact_#{order.evidence_bundle.id}",
        bundle_id: order.evidence_bundle.id,
        status: order.evidence_bundle.status,
        verification_status: order.evidence_bundle.verification_status,
        receipt_root: order.metadata_json["receipt_root"],
        download_url: order.metadata_json["download_url"],
        verification_command: order.metadata_json["verification_command"]
      }
    end

    def record_campaign_order(order)
      ::Campaign::ActivationRecorder.from_headers(request.headers).record_artifact_order_created(order)
    rescue StandardError
      nil
    end
  end
end

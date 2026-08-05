module Integrations
  module EventHandlers
    class ProducerPaymentRecordedHandler < BaseHandler
      def call
        project = developer_project
        projection = append_projection!(
          projection_type: "producer_payment",
          external_subject_id: data.fetch("payment_id"),
          current_state: state_for_parent(project),
          data_json: data.merge(authority_boundary: "payment execution remains upstream")
        )

        if project
          payment = create_payment_projection(project)
          map_external!(external_object_type: "producer_payment", external_object_id: data.fetch("payment_id"), record: payment) if payment
          receipt_request!(
            aggregate: projection,
            receipt_type: "producer_payment_receipt",
            schema_id: "athian.agevidence.payment.v1",
            payload: data.merge(
              event_id: event.external_event_id,
              project_internal_id: project.id,
              payment_projection_id: payment&.id
            )
          )
        end

        map_external!(external_object_type: "producer_payment_projection", external_object_id: data.fetch("payment_id"), record: projection)
        result
      end

      private

      def create_payment_projection(project)
        avsa = ensure_lightweight_avsa!(project)
        gross = BigDecimal(data.fetch("gross_amount").to_s)
        net = BigDecimal(data.fetch("producer_amount").to_s)
        deductions = gross - net
        ProducerPayment.find_or_create_by!(avsa: avsa, remittance_reference: data.fetch("transaction_reference")) do |record|
          record.producer_name = project.developer_account.name
          record.gross_amount = gross
          record.net_amount = net
          record.other_deductions = deductions
          record.currency = data.fetch("currency")
          record.status = payment_status
          record.paid_at = Time.zone.parse(data["payment_date"].to_s)
        end
      end

      def payment_status
        case data["payment_status"]
        when "paid", "remitted" then "remitted"
        when "failed" then "failed"
        else "pending"
        end
      end
    end
  end
end

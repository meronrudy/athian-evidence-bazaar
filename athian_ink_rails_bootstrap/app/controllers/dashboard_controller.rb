class DashboardController < ApplicationController
  def show
    @protocols = Protocol.order(:code)
    @avsas = Avsa.includes(:protocol, :receipts, :verification_exceptions).order(updated_at: :desc)
    @recent_receipts = Receipt.includes(:avsa).order(updated_at: :desc).limit(7)
    @recent_bundles = EvidenceBundle.includes(:avsa).order(generated_at: :desc).limit(5)
    @open_exceptions = VerificationException.includes(:avsa, :receipt)
                                            .where(status: "open")
                                            .order(severity: :desc, due_on: :asc)
    @verification_failures = VerificationRun.includes(:avsa, :receipt)
                                            .where(status: %w[invalid indeterminate])
                                            .recent_first
                                            .limit(5)
    @pending_attestations = Receipt.includes(:avsa)
                                   .where(lifecycle_state: %w[observed validated attested])
                                   .order(:sequence)
                                   .limit(6)
    @producer_payments = ProducerPayment.includes(:avsa).order(updated_at: :desc).limit(5)
    @migration_alerts = MethodologyMigration.includes(:avsa, :delta_receipt).order(created_at: :desc).limit(5)
    @recent_runs = VerificationRun.includes(:avsa, :receipt).recent_first.limit(5)

    @metrics = {
      evidence_awaiting_verification: EvidenceItem.joins(:receipt).where.not(status: "present").count,
      receipts_awaiting_attestation: Receipt.where(lifecycle_state: %w[observed validated attested]).count,
      producer_payments_awaiting_linkage: producer_payments_awaiting_linkage,
      methodology_migrations: MethodologyMigration.where(status: %w[pending impact_review appended]).count,
      bundles_generated_today: EvidenceBundle.where("generated_at >= ?", Time.current.beginning_of_day).count,
      trust_score: trust_score,
      local_verification_rate: local_verification_rate,
      evidence_completeness: evidence_completeness,
      producer_value_traceability: producer_value_traceability
    }
  end

  private

  def local_verification_rate
    total = VerificationRun.count
    return 0 if total.zero?

    (VerificationRun.where(status: "valid").count.to_f / total * 100).round
  end

  def evidence_completeness
    required = EvidenceItem.where(required: true)
    return 0 if required.none?

    (required.where(status: "present").count.to_f / required.count * 100).round
  end

  def producer_value_traceability
    total = ProducerPayment.count
    return 0 if total.zero?

    linked = ProducerPayment.joins(avsa: :receipts)
                            .where(receipts: { receipt_type: "producer_payment_receipt" })
                            .distinct.count
    (linked.to_f / total * 100).round
  end

  def producer_payments_awaiting_linkage
    ProducerPayment.includes(avsa: :receipts).count do |payment|
      payment.avsa.receipts.none? { |receipt| receipt.receipt_type == "producer_payment_receipt" }
    end
  end

  def trust_score
    components = [local_verification_rate, evidence_completeness, producer_value_traceability]
    (components.sum.to_f / components.size).round
  end
end

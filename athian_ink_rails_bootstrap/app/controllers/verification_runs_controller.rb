class VerificationRunsController < ApplicationController
  def new
    load_console
  end

  def create
    load_console
    if params[:intent] == "attest"
      append_attestation
      return
    end

    @receipt = @avsa.receipts.find_by(id: params[:receipt_id]) if params[:receipt_id].present?
    target = @receipt || @avsa
    result = InkVerifier.new(target: target).call

    @run = @avsa.verification_runs.create!(
      receipt: @receipt,
      status: result.fetch(:status),
      verifier_mode: result.fetch(:mode),
      message: result.fetch(:message),
      checks: result.fetch(:checks),
      started_at: result.fetch(:started_at),
      completed_at: result.fetch(:completed_at)
    )
    @result = result
    @recent_runs = @avsa.verification_runs.includes(:receipt).recent_first.limit(8)

    render :new
  end

  private

  def load_console
    @avsas = Avsa.includes(:protocol).order(:external_id)
    @avsa = @avsas.detect { |candidate| candidate.id.to_s == params[:avsa_id].to_s } || @avsas.first
    @receipts = @avsa ? @avsa.receipts.order(:sequence) : Receipt.none
    @exceptions = @avsa ? @avsa.verification_exceptions.where(status: "open") : VerificationException.none
    @recent_runs = @avsa ? @avsa.verification_runs.includes(:receipt).recent_first.limit(8) : VerificationRun.none
  end

  def append_attestation
    issued = InkReceipts.attest(
      avsa: InkProjection.avsa(@avsa),
      scope: params[:scope].presence || "Practice, measurement, model execution, issuance, claim, and payment evidence",
      materiality: params[:materiality].presence || "Exceptions below threshold after bounded review",
      evidence_sample: params[:evidence_sample].presence || "Feed invoice, lab report, model run, registry record, payment advice",
      exceptions: @exceptions.map { |exception| { code: exception.code, severity: exception.severity, materiality: exception.materiality } },
      issuer: @avsa.vvb_name.presence || "Independent Carbon Assurance LLC",
      signer: "did:key:vvb-demo"
    )

    receipt = @avsa.receipts.create!(
      receipt_type: issued.fetch(:receipt_type),
      title: issued.fetch(:title),
      lifecycle_state: issued.fetch(:lifecycle_state),
      domain_state: issued.fetch(:domain_state),
      issuer_name: issued.fetch(:issuer),
      signer_key_id: issued.fetch(:signer_key_id),
      schema_id: issued.fetch(:schema_id),
      schema_digest: issued.fetch(:schema_digest),
      body_digest: issued.fetch(:body_digest),
      evidence_commitment: issued.fetch(:evidence_commitment),
      policy_commitment: issued.fetch(:policy_commitment),
      trace_commitment: issued.fetch(:trace_commitment),
      sequence: @avsa.receipts.maximum(:sequence).to_i + 1,
      parent_receipt_ids: [@avsa.receipts.order(:sequence).last&.id].compact,
      canonical_encoding_hex: issued.fetch(:canonical_encoding_hex),
      integrity_status: issued.fetch(:integrity_status),
      signed_at: Time.current
    )

    @avsa.verification_runs.create!(
      receipt: receipt,
      status: "valid",
      verifier_mode: "ink_receipts",
      message: "Verifier Determination Receipt appended by ink_receipts.",
      checks: [
        { name: "attestation.scope", status: "valid", detail: "Scope declared" },
        { name: "attestation.materiality", status: "valid", detail: "Materiality declared" },
        { name: "attestation.append_only", status: "valid", detail: "New receipt appended; prior receipts untouched" }
      ],
      started_at: Time.current,
      completed_at: Time.current
    )

    redirect_to verifier_console_path(avsa_id: @avsa.id, receipt_id: receipt.id), notice: "Verifier Determination Receipt appended."
  end
end

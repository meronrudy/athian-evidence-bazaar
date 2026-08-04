class MethodologyMigrationsController < ApplicationController
  def index
    @avsas = Avsa.includes(:protocol).order(:external_id)
    @migrations = MethodologyMigration.includes(:avsa, :delta_receipt).order(created_at: :desc)
    @canonical_avsa = canonical_avsa
  end

  def show
    @migration = MethodologyMigration.includes(:avsa, :delta_receipt).find(params[:id])
  end

  def create
    avsa = Avsa.find(params.require(:avsa_id))
    issued = InkReceipts.migrate(
      avsa: InkProjection.avsa(avsa),
      old_methodology: { name: params[:old_methodology].presence || "VM0042", version: params[:old_version].presence || "v2.2" },
      new_methodology: { name: params[:new_methodology].presence || "VM0042", version: params[:new_version].presence || "v3.0" },
      affected_credits: params[:affected_credits].presence || avsa.verified_quantity,
      impact: params[:impact_summary].presence || "Recalculation lowers recognized reductions by 2.1% while preserving original issuance history."
    )

    receipt = avsa.receipts.create!(
      receipt_type: issued.fetch(:receipt_type),
      title: issued.fetch(:title),
      lifecycle_state: issued.fetch(:lifecycle_state),
      domain_state: "methodology_migration_appended",
      issuer_name: issued.fetch(:issuer),
      signer_key_id: issued.fetch(:signer_key_id),
      schema_id: issued.fetch(:schema_id),
      schema_digest: issued.fetch(:schema_digest),
      body_digest: issued.fetch(:body_digest),
      evidence_commitment: issued.fetch(:evidence_commitment),
      policy_commitment: issued.fetch(:policy_commitment),
      trace_commitment: issued.fetch(:trace_commitment),
      sequence: avsa.receipts.maximum(:sequence).to_i + 1,
      parent_receipt_ids: [avsa.receipts.order(:sequence).last&.id].compact,
      canonical_encoding_hex: issued.fetch(:canonical_encoding_hex),
      integrity_status: issued.fetch(:integrity_status),
      signed_at: Time.current,
      sealed_at: Time.current
    )

    migration = avsa.methodology_migrations.create!(
      delta_receipt: receipt,
      old_methodology: params[:old_methodology].presence || "VM0042",
      old_version: params[:old_version].presence || "v2.2",
      new_methodology: params[:new_methodology].presence || "VM0042",
      new_version: params[:new_version].presence || "v3.0",
      status: issued.fetch(:status),
      affected_credits: params[:affected_credits].presence || avsa.verified_quantity,
      impact_summary: issued.fetch(:impact),
      recalculation_payload: issued,
      appended_at: Time.current
    )

    redirect_to methodology_migration_path(migration), notice: "Methodology Delta Receipt appended."
  end
end

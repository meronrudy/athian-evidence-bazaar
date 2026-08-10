class PublicVerifierController < ApplicationController
  protect_from_forgery except: :create

  def show
    @identifier = params[:id].to_s.presence
    @receipt = find_receipt(@identifier) if @identifier
    @checks = @receipt ? receipt_checks(@receipt) : []
    @meta = receipt_meta(@receipt)

    respond_to do |format|
      format.html { render :show, status: @identifier.present? && @receipt.nil? ? :not_found : :ok }
      format.json { render json: verification_payload }
    end
  end

  def create
    identifier = params[:receipt_id].presence || params.dig(:verification, :receipt_id).presence

    if params.dig(:verification, :json_bundle).present?
      identifier ||= JSON.parse(params.dig(:verification, :json_bundle).read).dig("receipt", "id")
    end

    respond_to do |format|
      format.html do
        if identifier.present?
          redirect_to public_verifier_result_path(identifier)
        else
          redirect_to public_verifier_path, alert: "Enter a receipt ID."
        end
      end
      format.json do
        @identifier = identifier
        @receipt = find_receipt(identifier)
        @checks = @receipt ? receipt_checks(@receipt) : []
        render json: verification_payload, status: @receipt ? :ok : :not_found
      end
    end
  rescue JSON::ParserError => e
    respond_to do |format|
      format.html { redirect_to public_verifier_path, alert: "Invalid JSON bundle: #{e.message}" }
      format.json { render json: { status: "failed", error: e.message }, status: :unprocessable_entity }
    end
  end

  def lookup_by_url
    receipt = Receipt.find_by(body_digest: params[:url].to_s)
    if receipt
      render json: { status: "found", receipt_id: receipt.id, digest: receipt.body_digest }
    else
      render json: { status: "not_found" }, status: :not_found
    end
  end

  private

  def find_receipt(identifier)
    return nil if identifier.blank?

    clean = identifier.to_s.delete_prefix("receipt-")
    Receipt.find_by(id: clean) || Receipt.find_by(body_digest: identifier)
  end

  def receipt_meta(receipt)
    return [] unless receipt

    [
      ["Receipt ID", receipt.id, true],
      ["AVSA", receipt.avsa.external_id, true],
      ["Schema", receipt.schema_id, true],
      ["Hash", receipt.body_digest, true],
      ["Signer", receipt.signer_key_id, true],
      ["Lifecycle", receipt.lifecycle_state, false]
    ]
  end

  def receipt_checks(receipt)
    [
      ["Canonical digest", receipt.body_digest.present? ? "MATCH" : "MISSING", receipt.body_digest.present?],
      ["Issuer signature", receipt.signer_key_id.present? ? "VALID" : "MISSING", receipt.signer_key_id.present?],
      ["Evidence commitment", receipt.evidence_commitment.present? ? "MATCH" : "MISSING", receipt.evidence_commitment.present?],
      ["Policy commitment", receipt.policy_commitment.present? ? "MATCH" : "MISSING", receipt.policy_commitment.present?],
      ["Lifecycle", receipt.lifecycle_state.upcase, receipt.verified?]
    ]
  end

  def verification_payload
    if @receipt
      {
        status: @receipt.verified? ? "valid" : "indeterminate",
        receipt_id: @receipt.id,
        digest: @receipt.body_digest,
        checks: @checks
      }
    else
      { status: "not_found", receipt_id: @identifier }
    end
  end
end

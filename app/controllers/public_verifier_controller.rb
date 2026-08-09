class PublicVerifierController < ApplicationController
  # GET /verify
  # GET /verify/:id
  def show
    @verification = Verification.find(params[:id]) if params[:id]
    @receipt = Receipt.find(params[:receipt_id]) if params[:receipt_id]
  end

  # POST /verify
  def create
    # Handle verification request
    # This endpoint is called by external systems to verify evidence
    @verification = Verification.create(verification_params)
    render json: { success: true, verification_id: @verification.id }
  end

  # GET /verify/url?lookup_url=...
  def lookup_by_url
    @verification = Verification.find_by_url(params[:lookup_url])
    render json: { success: @verification.present?, verification_id: @verification&.id }
  end

  private

  def verification_params
    params.require(:verification).permit(
      :receipt_id,
      :verification_method,
      :verification_data,
      :integrity_hash,
      :verified_at
    )
  end
end
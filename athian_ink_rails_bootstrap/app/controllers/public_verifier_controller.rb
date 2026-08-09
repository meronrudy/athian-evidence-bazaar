class PublicVerifierController < ApplicationController
  def show
    @verification = Verification.find_by_url(params[:id]) || Verification.new
    respond_to do |format|
      format.html { render :show }
      format.json { render json: @verification }
    end
  end

  def create
    @verification = Verification.new(verification_params)

    # Process JSON bundle if provided
    if verification_params[:json_bundle]
      begin
        json_data = JSON.parse(verification_params[:json_bundle].read)
        @verification.process_json_bundle(json_data)
      rescue JSON::ParserError => e
        @verification.errors.add(:json_bundle, "Invalid JSON format: #{e.message}")
      end
    end

    # Verify receipt integrity if receipt_id provided
    if verification_params[:receipt_id]
      begin
        @verification.verify_receipt_integrity(verification_params[:receipt_id])
      rescue => e
        @verification.errors.add(:receipt_id, "Verification failed: #{e.message}")
      end
    end

    # Verify URL integrity if url provided
    if verification_params[:url]
      begin
        @verification.verify_url_integrity(verification_params[:url])
      rescue => e
        @verification.errors.add(:url, "Verification failed: #{e.message}")
      end
    end

    if @verification.save
      render json: { status: :success, verification_id: @verification.id }
    else
      render json: @verification.errors, status: :unprocessable_entity
    end
  end

  def lookup_by_url
    @verification = Verification.find_by_url(params[:url])
    if @verification
      render json: { status: :found, verification: @verification }
    else
      render json: { status: :not_found }, status: :not_found
    end
  end

  private
  def verification_params
    params.require(:verification).permit(:receipt_id, :url, :json_bundle)
  end
end
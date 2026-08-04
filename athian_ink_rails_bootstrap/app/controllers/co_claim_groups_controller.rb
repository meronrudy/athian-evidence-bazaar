class CoClaimGroupsController < ApplicationController
  before_action :set_avsa
  before_action :set_claim_group

  def show; end

  def update
    if @claim_group.update(claim_group_params)
      respond_to do |format|
        format.html { redirect_to avsa_co_claim_group_path(@avsa), notice: "Co-claim allocation updated." }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { render :show, status: :unprocessable_entity }
        format.turbo_stream { render :update, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_avsa
    @avsa = Avsa.find(params[:avsa_id])
  end

  def set_claim_group
    @claim_group = @avsa.claim_group
  end

  def claim_group_params
    params.require(:claim_group).permit(
      :finalization_status,
      claim_shares_attributes: %i[
        id claimant_name claimant_role share_percent contribution_amount
        inventory_category contract_right_digest status
      ]
    )
  end
end

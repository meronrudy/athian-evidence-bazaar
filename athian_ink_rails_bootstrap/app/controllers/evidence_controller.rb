class EvidenceController < ApplicationController
  def index
    @avsa = params[:avsa_id].present? ? Avsa.find(params[:avsa_id]) : canonical_avsa
    scope = EvidenceItem.joins(:receipt)
                        .includes(receipt: :avsa)
                        .order("receipts.sequence ASC", "evidence_items.name ASC")
    scope = scope.where(receipts: { avsa_id: @avsa.id }) if @avsa
    @evidence_items = scope
    @evidence_tree = @evidence_items.group_by(&:evidence_type)
  end
end

class ProtocolsController < ApplicationController
  def index
    @protocols = Protocol.includes(:avsas).order(:code)
  end

  def show
    @protocol = Protocol.includes(avsas: :receipts).find(params[:id])
  end
end

class GapsController < ApplicationController
  # GET /gaps
  # GET /gaps.json
  def index
    @gaps = Gap.all
  end

  # GET /gaps/1
  # GET /gaps/1.json
  def show
    @gap = Gap.find(params[:id])
  end
end
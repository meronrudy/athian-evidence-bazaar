class ApplicationController < ActionController::Base
  helper_method :canonical_avsa

  private

  def canonical_avsa
    @canonical_avsa ||= Avsa.order(:id).first
  end
end

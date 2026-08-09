class EvidenceInboxController < ApplicationController
  def index
    @evidence_events = EvidenceEvent.all.order(received_at: :desc)
  end
end
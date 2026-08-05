require "ink_receipts/integration_events"

module Agevidence
  class IntegrationSignatureVerifier
    def initialize(source:, envelope:)
      @source = source
      @envelope = envelope
    end

    def verify!
      raise InkReceipts::Error, "integration source is not active" unless source.active?

      InkReceipts::IntegrationEvents.verify!(
        envelope: envelope,
        algorithm: source.signing_algorithm,
        verification_key: source.resolved_verification_key
      )
    end

    private

    attr_reader :source, :envelope
  end
end

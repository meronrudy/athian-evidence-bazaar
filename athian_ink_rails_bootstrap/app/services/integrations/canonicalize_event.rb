module Integrations
  class CanonicalizeEvent
    def self.call(payload)
      canonical_payload = InkReceipts.canonicalize_integration_event(payload)
      {
        canonical_payload: canonical_payload,
        payload_digest: InkReceipts.integration_payload_digest(canonical_payload)
      }
    end
  end
end

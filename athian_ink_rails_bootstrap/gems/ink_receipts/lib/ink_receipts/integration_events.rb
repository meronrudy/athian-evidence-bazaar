require "openssl"

module InkReceipts
  class << self
    def canonicalize_integration_event(payload)
      Client.new.canonicalize_integration_event(payload)
    end

    def integration_payload_digest(canonical_payload)
      Client.new.integration_payload_digest(canonical_payload)
    end

    def sign_integration_payload(secret:, timestamp:, canonical_payload:)
      Client.new.sign_integration_payload(secret: secret, timestamp: timestamp, canonical_payload: canonical_payload)
    end

    def verify_integration_signature(algorithm:, secret:, public_key:, timestamp:, canonical_payload:, signature:)
      Client.new.verify_integration_signature(
        algorithm: algorithm,
        secret: secret,
        public_key: public_key,
        timestamp: timestamp,
        canonical_payload: canonical_payload,
        signature: signature
      )
    end
  end

  class Client
    def canonicalize_integration_event(payload)
      event = stringify_and_sort(payload)
      integrity = event.fetch("integrity", {}).dup
      integrity.delete("payload_digest")
      integrity.delete("signature")
      event["integrity"] = integrity if event.key?("integrity")
      canonical_json(event)
    end

    def integration_payload_digest(canonical_payload)
      "sha256:#{Digest::SHA256.hexdigest(canonical_payload)}"
    end

    def sign_integration_payload(secret:, timestamp:, canonical_payload:)
      input = integration_signing_input(timestamp: timestamp, canonical_payload: canonical_payload)
      "v1=#{OpenSSL::HMAC.hexdigest('SHA256', secret.to_s, input)}"
    end

    def verify_integration_signature(algorithm:, secret:, public_key:, timestamp:, canonical_payload:, signature:)
      case algorithm.to_s
      when "hmac_sha256"
        verify_hmac_integration_signature(
          secret: secret,
          timestamp: timestamp,
          canonical_payload: canonical_payload,
          signature: signature
        )
      when "ed25519"
        { status: "unsupported", message: "Ed25519 integration signatures are configured but not enabled in this scaffold." }
      else
        { status: "unsupported", message: "Integration signature algorithm is not supported." }
      end
    end

    private

    def verify_hmac_integration_signature(secret:, timestamp:, canonical_payload:, signature:)
      return { status: "invalid", message: "Missing integration verification secret." } if secret.to_s.empty?

      expected = sign_integration_payload(secret: secret, timestamp: timestamp, canonical_payload: canonical_payload)
      submitted = signature.to_s
      valid = expected.bytesize == submitted.bytesize &&
        OpenSSL.fixed_length_secure_compare(expected, submitted)
      {
        status: valid ? "valid" : "invalid",
        message: valid ? "Integration signature verified." : "Integration signature mismatch."
      }
    rescue StandardError => e
      { status: "invalid", message: e.message }
    end

    def integration_signing_input(timestamp:, canonical_payload:)
      "#{timestamp}\n#{canonical_payload}"
    end

    def stringify_and_sort(value)
      case value
      when Hash
        value.transform_keys(&:to_s).sort.to_h { |key, child| [key, stringify_and_sort(child)] }
      when Array
        value.map { |child| stringify_and_sort(child) }
      else
        value
      end
    end
  end
end

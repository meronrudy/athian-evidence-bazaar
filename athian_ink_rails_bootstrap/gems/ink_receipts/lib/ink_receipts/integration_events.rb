require "active_support/security_utils"
require "base64"
require "digest"
require "json"
require "openssl"

module InkReceipts
  module IntegrationEvents
    module_function

    def verify!(envelope:, algorithm:, verification_key:)
      normalized = stringify_keys(envelope)
      integrity = normalized.fetch("integrity") { raise InkReceipts::Error, "missing integrity object" }
      expected_digest = integrity.fetch("payload_digest") { raise InkReceipts::Error, "missing payload digest" }
      signature = integrity.fetch("signature") { raise InkReceipts::Error, "missing signature" }
      unsigned = normalized.reject { |key, _value| key == "integrity" }
      canonical = JSON.generate(canonicalize(unsigned))
      actual_digest = "sha256:#{Digest::SHA256.hexdigest(canonical)}"

      unless secure_compare(expected_digest, actual_digest)
        raise InkReceipts::Error, "integration payload digest mismatch"
      end

      verified = case algorithm.to_s
                 when "hmac_sha256"
                   verify_hmac(signature, actual_digest, verification_key)
                 when "ed25519"
                   verify_ed25519(signature, actual_digest, verification_key)
                 else
                   raise InkReceipts::Error, "unsupported integration signing algorithm: #{algorithm}"
                 end

      raise InkReceipts::Error, "integration event signature invalid" unless verified

      { payload_digest: actual_digest, signature_valid: true, algorithm: algorithm.to_s }
    rescue KeyError, ArgumentError, OpenSSL::OpenSSLError => e
      raise InkReceipts::Error, e.message
    end

    def canonical_digest(value)
      "sha256:#{Digest::SHA256.hexdigest(JSON.generate(canonicalize(value)))}"
    end

    def verify_hmac(signature, message, secret)
      raise InkReceipts::Error, "HMAC verification secret unavailable" if secret.to_s.empty?

      expected_hex = OpenSSL::HMAC.hexdigest("SHA256", secret, message)
      supplied = signature.to_s.sub(/\Ahmac-sha256=/, "")
      secure_compare(supplied.downcase, expected_hex.downcase)
    end

    def verify_ed25519(signature, message, public_key)
      raise InkReceipts::Error, "Ed25519 public key unavailable" if public_key.to_s.empty?

      key = OpenSSL::PKey.read(public_key)
      bytes = Base64.strict_decode64(signature.to_s.sub(/\Aed25519=/, ""))
      key.verify(nil, bytes, message)
    end

    def secure_compare(left, right)
      return false unless left.to_s.bytesize == right.to_s.bytesize

      ActiveSupport::SecurityUtils.secure_compare(left.to_s, right.to_s)
    end

    def canonicalize(value)
      case value
      when Hash
        value.keys.map(&:to_s).sort.each_with_object({}) do |key, output|
          original_key = value.key?(key) ? key : value.keys.find { |candidate| candidate.to_s == key }
          output[key] = canonicalize(value.fetch(original_key))
        end
      when Array
        value.map { |item| canonicalize(item) }
      else
        value
      end
    end

    def stringify_keys(value)
      case value
      when Hash
        value.each_with_object({}) { |(key, item), output| output[key.to_s] = stringify_keys(item) }
      when Array
        value.map { |item| stringify_keys(item) }
      else
        value
      end
    end
  end
end

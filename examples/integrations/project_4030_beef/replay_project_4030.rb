#!/usr/bin/env ruby
# frozen_string_literal: true

require "digest"
require "json"
require "net/http"
require "openssl"
require "time"
require "uri"

BASE_URL = ARGV.fetch(0, "http://localhost:3000")
SOURCE_KEY = ARGV.fetch(1, "athian_salesforce_production")
SECRET = ARGV.fetch(2) do
  ENV.fetch("ATHIAN_INTEGRATION_SECRET", "demo-integration-secret")
end

ROOT = File.expand_path(__dir__)
EVENT_FILES = Dir[File.join(ROOT, "[0-9][0-9]-*.json")].sort.freeze

def canonical_json(value)
  case value
  when Hash
    ordered = value.transform_keys(&:to_s).sort.to_h do |key, child|
      [key, canonical_value(child)]
    end
    JSON.generate(ordered)
  else
    JSON.generate(canonical_value(value))
  end
end

def canonical_value(value)
  case value
  when Hash
    value.transform_keys(&:to_s).sort.to_h { |key, child| [key, canonical_value(child)] }
  when Array
    value.map { |child| canonical_value(child) }
  else
    value
  end
end

def canonical_payload(event)
  copy = canonical_value(event)
  copy["source"] = SOURCE_KEY
  copy["integrity"] ||= {}
  copy["integrity"].delete("payload_digest")
  copy["integrity"].delete("signature")
  copy["integrity"]["signature_algorithm"] ||= "hmac-sha256"
  canonical_json(copy)
end

def signed_event(path)
  event = JSON.parse(File.read(path))
  event["source"] = SOURCE_KEY
  event["integrity"] ||= {}
  event["integrity"]["signature_algorithm"] = "hmac-sha256"

  canonical = canonical_payload(event)
  event["integrity"]["payload_digest"] = "sha256:#{Digest::SHA256.hexdigest(canonical)}"
  event["integrity"]["signature"] = "v1=#{OpenSSL::HMAC.hexdigest('SHA256', SECRET, "#{event.fetch('occurred_at')}\n#{canonical}")}"
  event
end

uri = URI.join(BASE_URL, "/v1/integrations/events")

EVENT_FILES.each do |path|
  event = signed_event(path)
  request = Net::HTTP::Post.new(uri)
  request["Content-Type"] = "application/json"
  request["X-Athian-Integration-Source"] = SOURCE_KEY
  request["X-Athian-Timestamp"] = event.fetch("occurred_at")
  request["X-Athian-Signature"] = event.dig("integrity", "signature")
  request.body = JSON.generate(event)

  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
    http.request(request)
  end

  puts "#{File.basename(path)} -> #{response.code} #{response.body}"
end

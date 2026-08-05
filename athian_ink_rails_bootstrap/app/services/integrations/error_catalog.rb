module Integrations
  module ErrorCatalog
    CODES = {
      source_unknown: "INTEGRATION_SOURCE_UNKNOWN",
      source_suspended: "INTEGRATION_SOURCE_SUSPENDED",
      invalid_json: "INVALID_JSON",
      event_id_missing: "EVENT_ID_MISSING",
      event_id_conflict: "EVENT_ID_PAYLOAD_CONFLICT",
      schema_version: "UNSUPPORTED_SCHEMA_VERSION",
      unknown_event_type: "UNKNOWN_EVENT_TYPE",
      digest_mismatch: "PAYLOAD_DIGEST_MISMATCH",
      signature_invalid: "SIGNATURE_INVALID",
      envelope_invalid: "ENVELOPE_SCHEMA_INVALID",
      event_invalid: "EVENT_SCHEMA_INVALID",
      event_too_large: "EVENT_TOO_LARGE",
      rate_limited: "RATE_LIMITED",
      internal_error: "INTERNAL_INGESTION_ERROR",
      signature_unsupported: "SIGNATURE_ALGORITHM_UNSUPPORTED"
    }.freeze

    MESSAGES = {
      CODES[:source_unknown] => "The integration source is not known.",
      CODES[:source_suspended] => "The integration source is not active.",
      CODES[:invalid_json] => "The event body is not valid JSON.",
      CODES[:event_id_missing] => "The event_id field is required.",
      CODES[:event_id_conflict] => "The event_id was already used with a different payload.",
      CODES[:schema_version] => "The schema_version is not supported.",
      CODES[:unknown_event_type] => "The event type is retained but not processed.",
      CODES[:digest_mismatch] => "The submitted payload digest does not match the canonical payload.",
      CODES[:signature_invalid] => "The event signature could not be verified.",
      CODES[:envelope_invalid] => "The event envelope does not satisfy the required contract.",
      CODES[:event_invalid] => "The event data does not satisfy the event-specific contract.",
      CODES[:event_too_large] => "The event body exceeds the configured size limit.",
      CODES[:rate_limited] => "The integration source is over its request limit.",
      CODES[:internal_error] => "The event could not be ingested.",
      CODES[:signature_unsupported] => "The integration signature algorithm is not enabled."
    }.freeze

    def self.message(code)
      MESSAGES.fetch(code, "The event could not be processed.")
    end
  end
end

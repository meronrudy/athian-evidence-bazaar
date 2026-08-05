import crypto from "node:crypto";

export function canonicalize(value) {
  if (Array.isArray(value)) {
    return value.map(canonicalize);
  }
  if (value && typeof value === "object") {
    return Object.keys(value)
      .sort()
      .reduce((acc, key) => {
        if (key === "integrity") {
          const integrity = { ...value[key] };
          delete integrity.payload_digest;
          delete integrity.signature;
          acc[key] = canonicalize(integrity);
        } else {
          acc[key] = canonicalize(value[key]);
        }
        return acc;
      }, {});
  }
  return value;
}

export function canonicalJson(value) {
  return JSON.stringify(canonicalize(value));
}

export function payloadCommitment(canonicalPayload) {
  return `sha256:${crypto.createHash("sha256").update(canonicalPayload).digest("hex")}`;
}

export function signPayload({ secret, timestamp, canonicalPayload }) {
  const input = `${timestamp}\n${canonicalPayload}`;
  const value = crypto.createHmac("sha256", secret).update(input).digest("hex");
  return `v1=${value}`;
}

export function buildEnvelope(record, env = process.env) {
  const data = typeof record.Payload__c === "string" ? JSON.parse(record.Payload__c) : record.Payload__c;
  const event = {
    event_id: record.Event_Id__c,
    event_type: record.Event_Type__c,
    schema_version: record.Schema_Version__c || "1.0.0",
    source: env.ATHIAN_INTEGRATION_SOURCE,
    occurred_at: record.Occurred_At__c,
    subject: {
      type: record.Object_Type__c,
      external_id: record.Object_Id__c
    },
    correlation: record.Correlation__c || {},
    data,
    integrity: {
      payload_digest: "pending",
      signature_algorithm: "hmac-sha256",
      signature: "pending"
    }
  };
  const canonicalPayload = canonicalJson(event);
  event.integrity.payload_digest = payloadCommitment(canonicalPayload);
  event.integrity.signature = signPayload({
    secret: env.ATHIAN_INTEGRATION_SECRET,
    timestamp: event.occurred_at,
    canonicalPayload
  });
  return event;
}

export async function handler(event, context = {}, env = process.env) {
  const record = event.detail || event;
  const envelope = buildEnvelope(record, env);
  const response = await fetch(env.AGEVIDENCE_ENDPOINT, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-Athian-Integration-Source": env.ATHIAN_INTEGRATION_SOURCE,
      "X-Athian-Event-Id": envelope.event_id,
      "X-Athian-Timestamp": envelope.occurred_at,
      "X-Athian-Signature": envelope.integrity.signature
    },
    body: JSON.stringify(envelope)
  });
  const body = await response.text();
  return {
    statusCode: response.status,
    body
  };
}

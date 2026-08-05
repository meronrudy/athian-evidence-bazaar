# Event Envelope

Every event uses the released envelope in:

```text
specs/integrations/evidence-event-envelope.v1.schema.json
```

Required fields:

```json
{
  "event_id": "evt_01J...",
  "event_type": "verification.status_changed",
  "schema_version": "1.0.0",
  "source": "athian_salesforce_production",
  "occurred_at": "2026-08-04T18:42:11Z",
  "subject": {
    "type": "verification_engagement",
    "external_id": "a1B8X0000042abc"
  },
  "correlation": {
    "project_id": "project-4030-001",
    "protocol_version_id": "au-beef-working-profile-0.3"
  },
  "data": {},
  "integrity": {
    "payload_digest": "sha256:...",
    "signature_algorithm": "hmac-sha256",
    "signature": "v1=..."
  }
}
```

Canonical commitments are computed over the canonical payload excluding
transport integrity fields. Rails stores the raw payload, canonical payload,
submitted digest, computed digest, signature, and verification status.

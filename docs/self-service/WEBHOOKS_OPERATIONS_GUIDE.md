# Webhooks and Operations Guide

Use operations to track asynchronous work and webhooks to receive artifact or
reliance result events.

Sandbox pricing and orders are illustrative planning records, not booked,
collected, or recognized revenue.

## Operations

The scaffold returns operation IDs for asynchronous processing. Poll:

```text
GET /v1/developer/operations/:external_id
GET /v1/integrations/operations/:external_id
```

Do not assume event processing, receipt issuance, verification, or artifact
assembly is complete inside the intake request.

## Webhook Endpoint API

```text
GET    /v1/integrations/webhook_endpoints
POST   /v1/integrations/webhook_endpoints
DELETE /v1/integrations/webhook_endpoints/:id
```

Outbound webhooks are separate from inbound integration signatures.

## Result Events

Initial result events:

- `artifact.ready`
- `artifact.verification_failed`
- `reliance.recorded`

Webhook payloads should contain references and statuses, not complete receipt
graphs or full source documents.

Typical artifact result:

```json
{
  "event_type": "artifact.ready",
  "external_project_id": "project-4030-001",
  "artifact_id": "artifact_...",
  "profile": "verification-readiness.au.v1",
  "receipt_root": "sha256:...",
  "integrity_status": "valid",
  "policy_compatibility": "review_required",
  "reliance_status": "not_yet_relied_upon",
  "download_url": "https://example.invalid/signed-download",
  "verification_command": "agevidence verify bundle.zip"
}
```

## Retry and Dead Letter

Webhook delivery failures are retried and then moved to a dead-letter state
after the retry budget is exhausted. Operators can inspect failed deliveries in
the integration administration pages.

## State Separation

Webhook consumers should preserve separate fields for cryptographic validity,
method compatibility, review status, artifact status, reliance status, and
payment status.

Do not collapse `integrity_status: valid` into scientific acceptance,
government approval, or institutional reliance.

## Related Guides

- [Webhook Flow](examples/webhook-flow.md)
- [Event Inbox Guide](EVENT_INBOX_GUIDE.md)
- [Troubleshooting](TROUBLESHOOTING.md)

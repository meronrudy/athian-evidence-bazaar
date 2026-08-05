# Webhook Flow

This walkthrough explains how a caller receives small result events from the
AgEvidence scaffold.

Sandbox pricing and orders are illustrative planning records, not booked,
collected, or recognized revenue.

## Register an Endpoint

```bash
curl -sS http://localhost:3000/v1/integrations/webhook_endpoints \
  -H "Content-Type: application/json" \
  -d '{
    "webhook_endpoint": {
      "url": "https://example.invalid/agevidence-webhooks",
      "subscribed_event_types": [
        "artifact.ready",
        "artifact.verification_failed",
        "reliance.recorded"
      ]
    }
  }'
```

Use a real HTTPS endpoint in production hardening. The scaffold documentation
uses `example.invalid` to avoid implying a live endpoint.

## Result Events

Initial outbound event types:

- `artifact.ready`
- `artifact.verification_failed`
- `reliance.recorded`

Outbound payloads contain artifact and status references only. They do not
return the complete receipt graph or full source evidence.

## Signing Headers

Outbound deliveries use a separate signing boundary from inbound integration
events:

```text
X-AgEvidence-Event-Id
X-AgEvidence-Timestamp
X-AgEvidence-Signature
```

## Inspect Delivery

Open:

```text
http://localhost:3000/integrations/deliveries
```

Failed deliveries can be inspected and retried through the internal integration
administration surfaces.

## State Boundaries

Webhook consumers should persist separate fields for cryptographic validity,
method compatibility, review status, artifact status, reliance status, and
payment status.

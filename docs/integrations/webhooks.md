# Outbound Webhooks

Initial outbound result events:

- `artifact.ready`
- `artifact.verification_failed`
- `reliance.recorded`

Headers:

```text
X-AgEvidence-Event-Id
X-AgEvidence-Timestamp
X-AgEvidence-Signature
```

Payloads include artifact and status references only. They do not include the
complete receipt graph.

Retry schedule:

```text
1 minute, 5 minutes, 30 minutes, 2 hours, 8 hours, 24 hours
```

After retry exhaustion the delivery moves to dead letter and remains inspectable
in Rails.

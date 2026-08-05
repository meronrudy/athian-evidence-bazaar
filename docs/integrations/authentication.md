# Integration Authentication

Inbound event authentication uses an `IntegrationSource`, not a developer API
token.

Required headers:

```text
X-Athian-Integration-Source: athian_salesforce_production
X-Athian-Event-Id: evt_01J...
X-Athian-Timestamp: 2026-08-04T18:42:11Z
X-Athian-Signature: v1=<hex>
Content-Type: application/json
```

The first supported signing mode is `hmac_sha256`. `ed25519` can be configured
on a source but returns `SIGNATURE_ALGORITHM_UNSUPPORTED` until trust-boundary
verification is enabled for that mode.

Integration signatures only prove that an authorized upstream system submitted
the event. They are not INK receipt signatures.

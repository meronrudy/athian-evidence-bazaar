# AWS Lambda Forwarder Example

This example shows the lowest-friction upstream bridge into the Rails
append-only inbox.

Responsibilities:

1. Receive a Salesforce Platform Event, S3 notification, or internal event.
2. Map it into one released integration event envelope.
3. Canonicalize the payload.
4. Compute the canonical payload commitment.
5. Sign the event.
6. POST it to `/v1/integrations/events`.
7. Persist and retry the delivery result using the same upstream event ID.

Required environment variables:

```text
AGEVIDENCE_ENDPOINT=https://example.com/v1/integrations/events
ATHIAN_INTEGRATION_SOURCE=athian_salesforce_production
ATHIAN_INTEGRATION_SECRET=replace-with-secret-manager-value
```

This example intentionally does not understand receipt schemas, country
adapters, model inference, or artifact assembly. It only declares a material
business event and forwards it to Rails.

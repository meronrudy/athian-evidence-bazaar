# AWS Lambda Forwarder

The Lambda forwarder receives a Salesforce Platform Event, S3 notification, or
internal event, maps it into the canonical envelope, computes the canonical
payload commitment, signs it, and posts it to Rails.

Responsibilities:

1. Preserve the upstream event ID.
2. Map business fields into one of the released event schemas.
3. Exclude transport integrity fields from the canonical commitment.
4. Sign the canonical payload.
5. Send `POST /v1/integrations/events`.
6. Persist the Rails response.
7. Retry with the same event ID.

The forwarder should not call receipt, verifier, country-adapter, or artifact
APIs.

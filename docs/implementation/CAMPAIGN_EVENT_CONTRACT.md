# Campaign Event Contract

Campaign events are attribution and connector events. They are separate from the
Evidence Event Inbox and must not reuse Evidence Event Inbox signatures as proof
of evidence receipt.

## Campaign Signal

`campaign-signal.v1` records a normalized signal from Apollo, Salesforce,
manual operators, SDK/CLI attribution, or Rails activation instrumentation.

Required semantics:

- every product-qualified signal points to a concrete repository object or
  recorded external obligation;
- every external reference names its source system;
- duplicate suppression uses source system, event type, aggregate, external
  reference, and idempotency key;
- raw private email bodies, OAuth refresh tokens, Apollo API keys, and
  unredacted evidence payloads are forbidden.

## Commercial Handoff

`commercial-handoff.v1` records the bounded payload sent to Salesforce after a
commercial qualification snapshot. It includes campaign account ID, developer
project ID, country code, product code, scope digest, planning value, gap count,
obligation code, and repository SHA.

Contracted and collected values are updated only from bounded inbound
Salesforce or finance signals.

## External Sync Result

`external-sync-result.v1` records connector delivery outcome, destination,
event type, idempotency key, status, attempt count, delivery timestamp, and
redacted error.

The result is operational telemetry only. It is not a receipt and does not
change evidence qualification.

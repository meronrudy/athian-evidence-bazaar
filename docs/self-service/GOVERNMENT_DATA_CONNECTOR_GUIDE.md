# Government Data Connector Guide

Government and registry connectors report source and transport observations. A successful HTTP request is not evidence approval.

Preserve these states when available:

- `request_accepted`
- `queued`
- `processed`
- `rejected`
- `rate_limited`
- `service_unavailable`
- `source_found`
- `source_not_found`
- `external_check_unavailable`
- `institutionally_accepted`

Every connector result should include the adapter id, country code, check id, reference payload, source commitment where available, findings, and limitations.


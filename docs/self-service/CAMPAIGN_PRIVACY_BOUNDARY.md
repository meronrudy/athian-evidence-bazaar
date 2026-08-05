# Campaign Privacy Boundary

The campaign surface stores only the data needed to route product activation and
handoff. It does not store complete Apollo profiles or raw email conversations.

## Stored Contact Data

- external contact ID;
- display name;
- role category;
- email domain;
- authority flags;
- contactability status;
- Apollo person ID and Salesforce contact ID when available;
- timestamps for enrichment and sync.

## Forbidden Data

- OAuth refresh tokens;
- Apollo API keys;
- full Apollo person profiles;
- raw private email bodies;
- unredacted source documents;
- producer banking information;
- presigned artifact URLs;
- unredacted evidence payloads.

## Suppression

An unsubscribe is terminal for that contact. Invalid contact data is not
repeatedly retried. Account-level outreach caps apply even when multiple
contacts are present.

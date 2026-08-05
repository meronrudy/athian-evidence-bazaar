# Campaign Operations Orientation

The campaign console answers which target accounts activated the Developer OS,
which evidence obligations are named, which accounts are ready for Salesforce,
and which reusable capabilities produced contracted or collected value.

## Daily Workflow

1. Review new Apollo-discovered accounts.
2. Approve a small number for technical outreach.
3. Send one bounded technical hypothesis and one relevant self-service entry
   point.
4. Watch activation paths, source records, signed events, model runs, gaps, and
   reliance events.
5. Evaluate technical qualification from repository state.
6. Create a Salesforce handoff only after commercial qualification.
7. Monitor connector outbox delivery and retry/dead-letter state.

## Operating Rules

- Do not qualify from Apollo reply, email open, or page view.
- Do not mark sandbox checkout as booked or collected revenue.
- Do not infer reliance from artifact generation or verification.
- Do not copy raw person profiles from Apollo.
- Do not mirror Salesforce opportunities in full.
- Do not log connector credentials, raw email bodies, source documents,
  producer banking information, presigned artifact URLs, or unredacted evidence
  payloads.

## Default Connectors

Development and test use fake Apollo and Salesforce connectors. HTTP connectors
require explicit credentials and are not required for local demo workflows.

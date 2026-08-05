# Campaign Control Plane

Grounded in commit `f4ec679c2dd6a2c40e3dced61c81e8f59f90a397`.

The campaign control plane connects target-account discovery, AgEvidence
developer activation, evidence-readiness signals, and bounded commercial
handoff. It is not a CRM, email client, billing system, or scientific approval
surface.

## Boundary

Campaign records belong in the `Campaign` namespace when they describe:

- target account identity needed for campaign routing;
- activation paths through the Developer OS, SDK, CLI, guides, or Event Inbox;
- evidence-grounded qualification snapshots;
- bounded Salesforce or Apollo connector state;
- product-to-revenue attribution for reusable capabilities.

Records remain in `Agevidence` when they describe:

- developer accounts and projects;
- source records;
- model runs, candidates, gaps, and reviews;
- country determinations;
- artifact orders, artifacts, and reliance events.

## Authority Rules

- Apollo is authoritative for discovery, enrichment, and outreach delivery.
- Salesforce is authoritative for durable commercial account, opportunity,
  contract, forecast, and collected-revenue references.
- AgEvidence is authoritative for developer activation, source records,
  evidence gaps, reviews, artifacts, and institutional reliance.
- Campaign state is authoritative only for attribution and routing.

## Negative Rules

- Campaign state never implies scientific approval.
- Commercial state never implies payment.
- Salesforce stage never implies technical qualification.
- Apollo reply never implies product activation.
- Sandbox checkout never creates booked, contracted, or collected revenue.
- Artifact generation or cryptographic validity never implies institutional
  reliance.
- External writes must pass through a transactional connector outbox.
- First-release behavior must work with fake connectors and fixtures.

## Minimum Release

The first release includes campaign accounts, contact references, activation
paths, touches, technical qualifications, commercial handoffs, connector outbox,
fake Salesforce and Apollo connectors, dashboard, v1 API, Python SDK namespace,
and CLI commands.

The release proves:

`target account -> technical activation -> real source or event -> evidence gap -> named external obligation -> qualified Architecture Sprint -> Salesforce handoff`

It does not prove automated enterprise sales, production billing, regulatory
acceptance, VVB approval, or recognized revenue.

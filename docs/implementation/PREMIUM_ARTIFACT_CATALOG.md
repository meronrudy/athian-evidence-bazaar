# Premium Artifact Catalog

Prices in the AgEvidence scaffold are illustrative management hypotheses. They are not quotes, commitments, booked revenue, or recognized revenue.

## Products

| Code | Product | Base planning price |
| --- | --- | ---: |
| `evidence_architecture_sprint` | Evidence Architecture Sprint | $25,000 |
| `protocol_evidence_implementation` | Protocol Evidence Implementation | $100,000 |
| `verification_readiness_cycle` | Verification Readiness Cycle | $60,000 |
| `enterprise_reliance_artifact` | Enterprise Reliance Artifact | $30,000 |
| `managed_evidence_plane` | Managed Evidence Plane | $150,000 per year |
| `private_deployment_model_registry` | Private Deployment Model Registry | $300,000 per year |
| `sponsor_portfolio_program` | Sponsor Portfolio Program | $200,000 per year |
| `methodology_migration_dispute_event` | Methodology Migration or Dispute Event | $250,000 |

## Pricing factors

Price according to:

- protocol complexity;
- evidence classes;
- source systems;
- review burden;
- relying-party count;
- transaction materiality;
- selective-disclosure requirements;
- response time;
- migration or dispute exposure.

Do not price according to tokens, API calls, signatures, receipt count, or bytes stored.

## Commercial proof

A generated bundle is not proof of commercial value. A recorded reliance event by a protocol, VVB, buyer, auditor, sponsor, or insurer is the north-star commercial signal.

## Country-aware artifacts

Premium artifacts are profile-driven. When a country determination exists, the generated bundle manifest should declare:

- country adapter ID and version;
- method ID and method version;
- claim policy;
- verification profile;
- data policy;
- artifact profile;
- determination receipt;
- evidence graph root;
- limitations;
- local verifier command.

The artifact builder should consume YAML profiles from `specs/agevidence/country_adapters/<country>/artifact_profiles`. It should not contain country-specific conditionals.

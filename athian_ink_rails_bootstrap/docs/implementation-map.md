# Implementation Map

## Strategic boundary translated into Rails

| Strategy requirement | Rails implementation | Boundary retained |
|---|---|---|
| Dashboard is not source of truth | Dashboard displays host projections and links to verifier | Canonical receipt and verifier remain authoritative |
| Generic lifecycle | `Receipt::LIFECYCLE_STATES` uses Draft → Observed → Validated → Attested → Sealed plus supersession/revocation states | Agricultural states remain `domain_state` values |
| Three-state verification | `InkVerifier` delegates to `InkReceipts.verify` and only returns valid, invalid, or indeterminate | Missing evidence is never treated as success |
| Co-claim aggregate cap | Nested share form, Stimulus exact-total control, server-side validation, duplicate-claimant rejection | Legal/scientific permissibility remains outside Rails |
| VVB first-class node | Verifier console exposes scope, exceptions, materiality, run record, and append-only attestation | Rails does not accredit or replace the VVB |
| Producer economics in the chain | Payment model and ledger link gross, deductions, net, status, and AVSA | Fairness requires explicit policy; it is not inferred |
| Open verification, paid reliance | `ink_receipts` facade and portable ZIP bundles | Commercial assembly does not trap core verification |
| Selective disclosure | Evidence items carry disclosure status and commitment | Source evidence remains access-controlled |

## Page inventory to Bootstrap component map

- Dashboard: cards, list groups, badges, progress bars, responsive tables.
- Evidence Explorer: grouped evidence tree with receipt, hash, signer, parent, lifecycle, and verify columns.
- Receipt chain: custom ledger rail plus Bootstrap cards and badges.
- Receipt detail: technical field table, evidence table, upload/input groups, verifier command, and download actions.
- Co-claim workbench: responsive table, collapsible detail rows, progress bar, nested form.
- Verifier console: forms, modal confirmation, exception list, result toast, audit table.
- Producer payment ledger: responsive table, collapsible reconciliation rows, status badges.
- Bundle Builder: four-step wizard, bundle cards, and generated ZIP download.
- Methodology Migration: VM0042 append-only delta receipt workflow.
- Evidence Marketplace: evidence-product pages with problem, receipts, command, and download.

## Canonical pilot sequence

1. Practice Receipt
2. Measurement Receipt
3. Model Execution Receipt
4. Verifier Receipt
5. Issuance Receipt
6. Claim Receipt
7. Producer Payment Receipt

The seed uses a linear parent chain for visual clarity. Contribution, retirement, VVB attestation, and methodology-delta receipts are append-only records displayed outside the seven-node hero chain.

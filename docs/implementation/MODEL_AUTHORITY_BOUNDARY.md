# Model Authority Boundary

## Rule

AgEvidence model adapters extract, classify, map, and identify gaps. They do not approve evidence, certify emissions reductions, issue AVSAs, determine legal rights, or make VVB determinations.

## Rails boundary

Rails may:

- collect source records and controlled references;
- start fixture, local, or remote model runs;
- persist normalized model output exactly as received;
- record human review decisions;
- request receipt issuance through `InkReceipts`;
- display artifacts, revenue scenarios, and reliance events.

Rails must not:

- calculate receipt commitments;
- sign receipts;
- evaluate trust policy validity;
- convert confidence into scientific validity;
- overwrite historical model runs or review decisions.

## Python boundary

The Python service may:

- run a fixture adapter by default;
- call configured local or remote model endpoints later;
- return normalized candidates, gaps, limitations, and model-run metadata.

The Python service must not:

- sign receipts;
- write directly to Rails data stores;
- approve evidence;
- certify protocol or verifier outcomes.

## Rust and ink_receipts boundary

The trust layer owns payload validation, canonical commitments, receipt issuance, bundle construction, graph export, and verification outcomes.

The `baink-agevidence` crate is currently structural validation scaffold. Production completion should replace its lightweight field checks with schema-backed validation without adding model-runtime dependencies.

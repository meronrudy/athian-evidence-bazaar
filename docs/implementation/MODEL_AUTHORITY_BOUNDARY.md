# Model Authority Boundary

## Rule

AgEvidence model adapters extract, classify, map, and identify gaps. They do not approve evidence, certify emissions reductions, issue AVSAs, determine legal rights, or make VVB determinations.

## Rails boundary

Rails may:

- collect source records and controlled references;
- start fixture, local, or remote model runs;
- persist normalized model output exactly as received;
- attach country context to a model-run request;
- run declarative country compatibility evaluation through adapter-pack data;
- record human review decisions;
- request receipt issuance through `InkReceipts`;
- display artifacts, revenue scenarios, and reliance events.

Rails must not:

- calculate receipt commitments;
- sign receipts;
- evaluate trust policy validity;
- define national methodology rules in controllers or templates;
- convert confidence into scientific validity;
- present Athian compatibility as government eligibility;
- infer claim rights from funding share or payment;
- overwrite historical model runs or review decisions.

## Python boundary

The Python service may:

- run a fixture adapter by default;
- call configured local or remote model endpoints later;
- receive optional country adapter context;
- normalize terminology and identify possible evidence gaps;
- return normalized candidates, gaps, limitations, and model-run metadata.

The Python service must not:

- sign receipts;
- write directly to Rails data stores;
- approve evidence;
- certify protocol or verifier outcomes.
- declare final method eligibility, legal validity, claim ownership, credit approval, or verified reductions.

## Rust and ink_receipts boundary

The trust layer owns payload validation, canonical commitments, receipt issuance, bundle construction, graph export, and verification outcomes.

The `baink-agevidence` crate is currently structural validation scaffold. Production completion should replace its lightweight field checks with schema-backed validation without adding model-runtime or country-policy dependencies.

## Country boundary

Country adapters are versioned data packs. They may declare method scope, required evidence, excluded contexts, claim policy, verification profile, data policy, artifact profile, and limitations.

They must not change the canonical receipt envelope, cryptographic verifier, Rails workflow, or Python runtime. A country determination is an Athian compatibility assessment only and remains separate from external institutional reliance.

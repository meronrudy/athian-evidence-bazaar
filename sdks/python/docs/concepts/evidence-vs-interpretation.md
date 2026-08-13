# Evidence vs. Interpretation

Agevidence separates evidence from interpretation.

Evidence records what happened. Interpretation decides what that evidence means
under a model, methodology, program, institution, claim, or review process.

## Evidence Layer

Evidence primitives answer:

- What happened?
- What was measured?
- When?
- Where?
- By which system?
- Using which instrument?
- Using which units?
- Derived from which source?
- Through which transformation?

The local evidence layer includes:

- `SourceRecord`
- `Observation`
- `SpatialObservation`
- `InterventionEvent`
- `OperationalEvent`
- `ModelRun`

## Interpretation Layer

Interpretation objects answer:

- What does this evidence mean under framework X?
- Is it eligible?
- Who may rely on it?
- Who may claim the result?
- Which model, method, profile, reviewer, or institution made the decision?

Examples include:

- program profile;
- method version;
- eligibility determination;
- claim allocation;
- verification decision;
- reliance decision.

## Rule

Updating a methodology or program profile should not mutate historical evidence.

The same historical evidence can be evaluated by multiple versioned models,
profiles, or institutions without rewriting the original source record,
observation, intervention, operation, or model execution.

Local `PASS` means Agevidence checked structure, provenance, lineage,
deterministic representation, and contract compatibility. It does not establish
regulatory eligibility, scientific validity, carbon-credit issuance, third-party
verification, claim ownership, or institutional reliance.


# Agevidence SDK Constitution

## First Principle

The Agevidence SDK represents evidence. It does not own the interpretation of that evidence.

Agevidence records facts and provenance below the waist. Models, methods, programs, claims, and institutions interpret them above the waist.

A fact should not need to change because the institution asking about it changed.

## Thin-Waist Boundary

The SDK-owned evidence waist includes:

- what happened;
- what was observed;
- what was applied;
- when, where, and to what;
- the actor, instrument, source system, source record, units, and quantity;
- transformations, lineage, limitations, commitments, and signatures.

The SDK core must not decide:

- whether a country program accepts evidence;
- whether a market or Scope 3 claim is valid;
- whether an insurer, verifier, buyer, registry, or regulator may rely on a result;
- whether a methodology accepts an intervention;
- who owns, allocates, or retires a claim.

Those are versioned interpretations above the waist.

## Dependency Direction

The dependency direction is one way:

```text
programs / markets / institutions
profiles and policy packs
model runs
canonical evidence waist
agevidence.primitives / provenance / local
source systems, sensors, APIs, machinery
```

`agevidence.primitives`, `agevidence.provenance`, and `agevidence.local` must not import hosted client code, campaign code, country adapters, profile evaluators, billing, Rails projections, or institutional workflows.

Profiles may evaluate evidence. Evidence primitives must not depend on profiles.

## Authority Hierarchy

When implementations disagree, authority flows in this order:

1. Canonical Evidence Specification under `specs/agevidence/schemas`
2. Golden conformance fixtures
3. Rust deterministic validation
4. Python SDK
5. Rails projections and hosted control plane
6. Country, program, and institution profiles
7. Commercial workflows

Packaged SDK schemas are mirrors of the specification, not independent authorities.

## Primitive Admission

A field can enter a canonical primitive only if it passes all checks:

1. It describes evidence semantics rather than policy.
2. It applies across at least three materially different source systems.
3. It remains meaningful when current company names are removed.
4. It does not encode one country program.
5. It does not encode one carbon methodology.
6. It remains meaningful outside carbon markets.
7. Historical evidence would still mean the same thing if downstream methods changed.
8. An independent implementation could reproduce the same semantic meaning.

Wave-specific, customer-specific, program-specific, or methodology-specific concepts start in adapters, extensions, metadata, or profiles. They graduate to primitives only after repeated reuse proves they are waist semantics.

## No Destructive Reinterpretation

Committed evidence is append-only. A later model, profile, or rule must not rewrite an observation, intervention, source record, operation, or model run.

New interpretations must point backward through commitments and lineage:

```text
Observation
├── ModelRun v1
├── ModelRun v2
├── Country/Profile Determination
└── Reliance Artifact
```

## Version Dimensions

Do not collapse package and semantic versions:

- Python SDK package version, for example `agevidence==1.0.0`
- Canonical Evidence Contract version
- Primitive schema identifiers, for example `athian.agevidence.observation.v1`
- Country/program/profile versions, for example `au-livestock-2026.3`

Updating the Python package must not silently mutate what a versioned primitive means.

## Offline Independence

Basic protocol use must work with no Rails app, no Agevidence API key, no database, no company credentials, and no hosted network calls.

The local SDK must support fixture loading, ingest, explanation, portable export, and deterministic verification delegation without requiring Agevidence, Inc. to operate a service.

## Schema Stability Budget

Every release or Wave integration should account for:

- core primitives added or removed;
- core fields added or removed;
- extensions introduced;
- extensions promoted to core;
- company-specific mappings;
- profile-specific mappings.

The healthy pattern is many more integrations with stable primitive and field counts.

## PR Review Questions

Every major SDK or schema PR must answer:

1. Does this describe agricultural evidence or an interpretation of evidence?
2. Can at least three unrelated systems use this concept?
3. Would it remain meaningful if carbon markets disappeared?
4. Can the resulting evidence still be used without hosted Agevidence services?
5. Does this make the tenth integration easier than the second?

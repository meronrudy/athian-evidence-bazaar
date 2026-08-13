# ADR 0009: Canonical Field Admission

Status: Accepted

Canonical primitive fields are governed as thin-waist evidence semantics. They must not encode one company, source integration, country program, carbon methodology, claim workflow, hosted service, or institutional reliance decision.

New source-system needs should start in adapters, extensions, profile rules, or metadata. A field may move into a canonical primitive only after review confirms it is reusable across at least three materially different source systems and remains meaningful outside the current regulatory or market interpretation.

Schema pull requests must include a field-admission checklist and update golden fixtures plus Rust/Python conformance tests. If the Python SDK and Rails projections disagree, `specs/agevidence/schemas` wins. If Rust and Python disagree, conformance fails until both match the specification.

This ADR reinforces the no-destructive-reinterpretation rule: historical evidence objects remain unchanged when models, methods, profiles, or reliance workflows evolve.

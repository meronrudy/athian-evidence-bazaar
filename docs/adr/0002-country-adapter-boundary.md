# ADR 0002: Country Adapter Boundary

Status: Accepted

Country adapters translate local identifiers, source records, external check outcomes, and policy requirements into stable AgEvidence contracts. They do not create new receipt envelopes, trust kernels, Rails applications, or approval states.

Executable adapter code lives in typed Python plugins. Declarative country packs remain under `specs/agevidence/country_adapters` and may select or describe plugins, but YAML files must never dynamically load arbitrary code.


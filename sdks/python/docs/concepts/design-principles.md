# Design Principles

1. Evidence before interpretation

   Record what happened independently of what a program later decides.

2. Provenance is first-class

   Source, instrument, transformation, and lineage travel with the evidence.

3. Local-first

   Core SDK functionality does not require a hosted Agevidence service.

4. Deterministic where trust matters

   Verification and canonicalization produce reproducible results.

5. Adapters at the edges, stable primitives at the center

   Source-system quirks should not expand the canonical contract.

6. Version interpretations, do not rewrite history

   Models and profiles may evolve while original evidence remains unchanged.

7. Portable by design

   Independent tools should be able to inspect and verify
   Agevidence-compatible artifacts.


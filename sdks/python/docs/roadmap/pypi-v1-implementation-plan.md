# Agevidence Python SDK PyPI v1 Implementation Plan

This roadmap defines the work needed to move the `agevidence` Python package
from its completed alpha baseline to a full-featured `1.0.0` PyPI release.

Current baseline:

- PyPI distribution: `agevidence`
- Python namespace: `agevidence`
- CLI: `agevidence`
- Completed alpha baseline: `0.2.0a1`
- Current v1 target: `1.0.0`
- Release mechanism: GitHub trusted publisher through `sdk-python-release.yml`
- Source: `sdks/python`

## V1 Release Definition

The v1 SDK is ready when a developer who has never spoken to Agevidence can:

1. install the package from PyPI;
2. run a no-account local demo;
3. map a native record into a canonical primitive;
4. understand missing provenance;
5. test a source adapter against fixtures;
6. validate primitives against published schemas;
7. delegate bundle verification to the Rust verifier when configured;
8. use CI helpers to enforce local evidence quality;
9. optionally connect to hosted Agevidence APIs;
10. rely on documented compatibility guarantees for the stable v1 surface.

Local `PASS` must always mean local structure, provenance, lineage,
deterministic representation, or contract compatibility. It must not imply
regulatory eligibility, scientific validity, carbon-credit issuance, third-party
verification, claim ownership, or institutional reliance.

## Milestone 0: Baseline Freeze and Release Inventory

Goal: establish the exact alpha baseline that v1 work starts from.

Parent tasks:

- [ ] Freeze current SDK baseline.
  - [ ] Record current package version from `sdks/python/pyproject.toml`.
  - [ ] Record current `agevidence.__version__`.
  - [ ] Capture `python3 -m pytest sdks/python` result.
  - [ ] Capture `cargo test --workspace` result.
  - [ ] Capture `bash scripts/agevidence_check_all.sh` result.
  - [ ] Capture `python3 scripts/check_sdk_release_readiness.py` result.

- [ ] Inventory public surfaces.
  - [ ] List stable candidate APIs in `agevidence.primitives`.
  - [ ] List experimental APIs in `agevidence.ingest` and `agevidence.adapters.Adapter`.
  - [ ] List profile-specific APIs in `CountryAdapter` and built-in country packs.
  - [ ] List hosted-only APIs in `Client` and `AsyncClient`.
  - [ ] Identify all CLI command groups and whether each is local, profile-specific, or hosted.

- [ ] Inventory packaged artifacts.
  - [ ] Confirm `py.typed` is packaged.
  - [ ] Confirm fixture JSON files are packaged.
  - [ ] Confirm schema JSON files are packaged.
  - [ ] Confirm `docs/pypi.md` renders cleanly through `twine check`.
  - [ ] Confirm wheel and sdist contain no stale internal branding.

Exit gate:

- [ ] Baseline is documented in release notes or an SDK tracking issue.
- [ ] Current tests and release-readiness checks are reproducible from a clean checkout.

## Milestone 1: Stable Evidence Primitive Contract

Goal: make the evidence primitive layer the stable v1 thin waist.

Parent tasks:

- [ ] Finalize v1 primitive field contracts.
  - [ ] `SourceRecord`: source system, record id, observed timestamp, controlled URI, commitment, metadata, limitations.
  - [ ] `Observation`: subject, observable, value, unit, observed timestamp, instrument, method, source records, metadata, limitations.
  - [ ] `SpatialObservation`: geometry, observable, value, unit, CRS, observed timestamp, source records, metadata, limitations.
  - [ ] `InterventionEvent`: target, intervention, quantity, unit, occurred timestamp, batch, source records, metadata, limitations.
  - [ ] `OperationalEvent`: machine, operation, started timestamp, completed timestamp, location, source records, metadata, limitations.
  - [ ] `ModelRun`: model id, model version, implementation digest, input commitments, parameters, execution environment, timestamps, outputs, limitations, verification, metadata.

- [ ] Stabilize schema alignment.
  - [ ] Ensure each primitive has a JSON schema under `specs/agevidence/schemas`.
  - [ ] Ensure packaged schemas under `agevidence.schemas` match repo schemas.
  - [ ] Ensure schema `$id` values match docs and primitive `schema_id` values.
  - [ ] Ensure malformed golden fixtures fail both Python checks and Rust validation where applicable.
  - [ ] Ensure valid golden fixtures pass Python checks and Rust validation where applicable.

- [ ] Stabilize deterministic representation.
  - [ ] Keep `canonical_json` deterministic.
  - [ ] Keep `local_digest` deterministic and documented as not a receipt commitment.
  - [ ] Add regression fixtures for ordering, optional fields, and numeric/string edge cases.
  - [ ] Add tests that repeated serialization produces identical local digests.

- [ ] Define v1 compatibility policy.
  - [ ] Document additive changes allowed in v1.
  - [ ] Document breaking changes that require v2.
  - [ ] Document deprecation behavior for alpha compatibility aliases.
  - [ ] Mark any non-v1 primitive fields as experimental or legacy.

Exit gate:

- [ ] `agevidence.primitives` is documented as the v1 stable contract.
- [ ] All primitive schemas and golden fixtures pass Python and Rust conformance.

## Milestone 2: Local Ingest and Source Adapter Self-service

Goal: make native-record mapping usable without synchronous support.

Parent tasks:

- [ ] Harden deterministic ingest.
  - [ ] Keep `agevidence ingest RECORD` local and no-network.
  - [ ] Preserve JSON default output for compatibility.
  - [ ] Keep `--format table` for developer-readable output.
  - [ ] Return candidate primitive type, confidence, matched fields, primitive payload, provenance report, local digest, and committed state.
  - [ ] Add tests for ambiguous mappings and explicit `--primitive` override.

- [ ] Harden `agevidence.adapters.Adapter`.
  - [ ] Keep the source adapter interface separate from `CountryAdapter`.
  - [ ] Support adapter specs as `path.py`, `path.py:ObjectName`, and `module:ObjectName`.
  - [ ] Support one or many primitives returned from `map`.
  - [ ] Reject unknown canonical primitive shapes.
  - [ ] Report deterministic local digests for mapped outputs.

- [ ] Harden `agevidence adapter test`.
  - [ ] Accept a single JSON fixture file.
  - [ ] Accept a directory of JSON fixtures.
  - [ ] Report fixture count, mapped count, structurally valid count, provenance complete/partial/incomplete/indeterminate counts, failures, and schema-extension state.
  - [ ] Exit nonzero for adapter exceptions, invalid primitives, unknown primitive types, or schema extensions.
  - [ ] Keep authority-boundary text in table and JSON output.

- [ ] Add adapter examples.
  - [ ] Methane sensor adapter.
  - [ ] Livestock measurement adapter.
  - [ ] Feed intervention adapter.
  - [ ] Machine operation adapter.
  - [ ] Multi-output adapter example.

Exit gate:

- [ ] A new developer can build and test one source adapter from docs with no hosted service.
- [ ] Adapter tests do not conflate source mapping with country/profile interpretation.

## Milestone 3: Provenance, Explanation, and Authority Boundaries

Goal: make missing evidence context actionable without overclaiming.

Parent tasks:

- [ ] Finalize provenance report contract.
  - [ ] Keep `structural_validity`.
  - [ ] Keep `provenance_completeness`.
  - [ ] Keep `program_eligibility` as `not_evaluated` for local checks.
  - [ ] Keep `verification_status` as `not_issued` for local checks.
  - [ ] Keep `institutional_reliance` as `not_asserted` for local checks.
  - [ ] Keep `authority_boundary` in reports.

- [ ] Improve provenance finding coverage.
  - [ ] Source record presence.
  - [ ] Instrument id presence.
  - [ ] Calibration reference coverage.
  - [ ] Intervention batch reference.
  - [ ] Model implementation digest.
  - [ ] Model input commitments.
  - [ ] Model execution environment.
  - [ ] Model verification metadata.

- [ ] Harden `agevidence explain`.
  - [ ] Preserve JSON default output.
  - [ ] Keep `--format table` output readable.
  - [ ] Show missing findings.
  - [ ] Show warnings.
  - [ ] Show remediation hints.
  - [ ] Show `does_not_establish`.
  - [ ] Never print text that implies approval, issuance, or reliance.

- [ ] Add authority-boundary regression tests.
  - [ ] Local PASS does not mention approval.
  - [ ] Adapter PASS does not mention verification.
  - [ ] Country compatibility does not claim regulator approval.
  - [ ] Hosted model output remains candidate evidence unless reviewed.

Exit gate:

- [ ] Every user-facing local success output includes or links to the authority boundary.
- [ ] Missing provenance is actionable for a developer.

## Milestone 4: Local Verification and Rust Trust Boundary

Goal: make verifier delegation reliable while keeping Python out of the trust kernel.

Parent tasks:

- [ ] Harden Python verifier delegation.
  - [ ] Keep `agevidence verify BUNDLE`.
  - [ ] Keep compatibility option `--bundle`.
  - [ ] Call configured verifier as `baink-cli verify BUNDLE --json`.
  - [ ] Return useful errors for missing command, missing executable, and verifier failure.
  - [ ] Preserve sync-only verifier delegation.

- [ ] Harden Rust conformance bridge.
  - [ ] Keep `assert_rust_conformant`.
  - [ ] Ensure schema aliases match Rust CLI schema names.
  - [ ] Ensure fixture tests cover observation, spatial observation, intervention, operational event, model run, and legacy model execution where needed.
  - [ ] Document verifier setup in docs and release notes.

- [ ] Preserve trust boundary.
  - [ ] Python does not sign receipts.
  - [ ] Python does not compute receipt commitments.
  - [ ] Python does not implement dCBOR.
  - [ ] Python does not verify bundles internally.
  - [ ] Rails remains outside cryptographic verification.

Exit gate:

- [ ] Verifier-enabled environments pass delegated validation and verification.
- [ ] Verifier-missing environments still pass local-first demo, ingest, explain, and adapter tests.

## Milestone 5: Hosted Client v1 Surface

Goal: make optional hosted APIs usable without moving local-first behavior behind hosted setup.

Parent tasks:

- [ ] Stabilize sync client resource namespaces.
  - [ ] Projects.
  - [ ] Source records.
  - [ ] Model runs.
  - [ ] Candidate review.
  - [ ] Pricing and quotes.
  - [ ] Orders and checkout.
  - [ ] Artifacts.
  - [ ] Operations.
  - [ ] Integration events and replay.
  - [ ] Webhooks.
  - [ ] Country/profile adapters.
  - [ ] Campaign workflows, if included in v1.

- [ ] Stabilize async client parity.
  - [ ] Mirror sync resource namespaces.
  - [ ] Match response models.
  - [ ] Match retry behavior where applicable.
  - [ ] Document sync-only verifier delegation.

- [ ] Harden hosted transport.
  - [ ] Retry policy documented and tested.
  - [ ] Idempotency key support documented and tested for mutating resource methods.
  - [ ] Bearer token behavior documented.
  - [ ] Error payload model documented.
  - [ ] Timeout behavior documented.

- [ ] Keep hosted boundary explicit.
  - [ ] Hosted API setup is optional.
  - [ ] Hosted workflows do not change local evidence semantics.
  - [ ] Model output remains candidate evidence.
  - [ ] Artifact generation does not imply institutional reliance.

Exit gate:

- [ ] Hosted client docs and tests cover all v1-supported resource namespaces.
- [ ] Local-first commands pass without hosted environment variables.

## Milestone 6: Country/Profile Adapter and Interpretation Boundary

Goal: support profile-specific interpretation while preserving evidence portability.

Parent tasks:

- [ ] Stabilize `CountryAdapter` contract for v1.
  - [ ] Adapter metadata.
  - [ ] Identifier normalization.
  - [ ] Source record normalization.
  - [ ] Local context validation.
  - [ ] Evidence requirements.
  - [ ] External checks.
  - [ ] Policy stack.
  - [ ] Evaluation result.

- [ ] Stabilize built-in country/profile packs included in v1.
  - [ ] Decide which packs are active, pilot, scaffold, or research.
  - [ ] Ensure manifests validate against schemas.
  - [ ] Ensure packaged manifest snapshots match repo specs.
  - [ ] Ensure cross-country conformance keeps evidence root stable.

- [ ] Harden CLI interpretation commands.
  - [ ] `agevidence adapters list`.
  - [ ] `agevidence adapters show`.
  - [ ] `agevidence adapters validate`.
  - [ ] `agevidence identifiers normalize`.
  - [ ] `agevidence sources normalize`.
  - [ ] `agevidence sources check`.
  - [ ] `agevidence fixtures run`.

- [ ] Preserve interpretation boundary.
  - [ ] Country/profile adapter output is compatibility assessment only unless an external authority issues a separate decision.
  - [ ] Country/profile output does not mutate the source evidence.
  - [ ] Country/profile output does not claim credit issuance, verification, or institutional reliance.

Exit gate:

- [ ] Cross-country conformance tests pass.
- [ ] Country/profile docs explain interpretation without making the package look country-specific on first use.

## Milestone 7: Documentation and Developer Experience

Goal: make docs the primary integration path for external developers.

Parent tasks:

- [ ] Complete external docs sequence.
  - [ ] Homepage.
  - [ ] Quickstart.
  - [ ] Evidence vs. interpretation.
  - [ ] Primitives.
  - [ ] Provenance.
  - [ ] Model runs.
  - [ ] Trust boundary.
  - [ ] Local-first and portable.
  - [ ] Design principles.

- [ ] Complete guides.
  - [ ] Ingest native JSON.
  - [ ] Build an observation.
  - [ ] Build an intervention event.
  - [ ] Record a model run.
  - [ ] Check provenance.
  - [ ] Verify locally.
  - [ ] Use in CI.
  - [ ] Build a source adapter.

- [ ] Complete reference.
  - [ ] Python API.
  - [ ] CLI.
  - [ ] Schemas.
  - [ ] Compatibility.
  - [ ] Conformance.
  - [ ] This v1 roadmap.

- [ ] Complete examples.
  - [ ] Livestock measurement.
  - [ ] Methane sensor.
  - [ ] Feed intervention.
  - [ ] Spatial observation.
  - [ ] Machine operation.

- [ ] Complete optional hosted docs.
  - [ ] Hosted overview.
  - [ ] Hosted client.
  - [ ] Projects.
  - [ ] Institutional services.

- [ ] Improve first-run copy.
  - [ ] `agevidence demo` output is clear.
  - [ ] `agevidence doctor` output is clear.
  - [ ] `agevidence ingest --format table` output is clear.
  - [ ] `agevidence explain --format table` output is clear.
  - [ ] `agevidence adapter test` output is clear.

Exit gate:

- [ ] A developer can complete demo, ingest, explain, adapter test, and CI helper setup using docs only.
- [ ] PyPI README describes the same local-first path as repository docs.

## Milestone 8: Packaging, CI, and Release Automation

Goal: make v1 publishing repeatable and auditable.

Parent tasks:

- [ ] Harden package metadata.
  - [ ] Version is `1.0.0`.
  - [ ] `agevidence.__version__` matches `pyproject.toml`.
  - [ ] Classifier moves out of alpha.
  - [ ] Description reflects v1 scope.
  - [ ] Project URLs are correct.
  - [ ] Required Python versions are intentional.

- [ ] Harden package contents.
  - [ ] Include typed marker.
  - [ ] Include fixtures.
  - [ ] Include schemas.
  - [ ] Exclude caches, build artifacts, local test outputs, and obsolete generated metadata.
  - [ ] Verify wheel install in a clean virtual environment.
  - [ ] Verify sdist install in a clean virtual environment.

- [ ] Harden release workflow.
  - [ ] Trusted publisher configured for PyPI.
  - [ ] No long-lived PyPI API token.
  - [ ] Tag pattern is `sdk-python-v1.0.0`.
  - [ ] Build runs from `sdks/python`.
  - [ ] `twine check dist/*` runs.
  - [ ] Draft GitHub release is created.

- [ ] Harden CI.
  - [ ] `python3 -m pytest sdks/python`.
  - [ ] `cargo test --workspace`.
  - [ ] `bash scripts/agevidence_check_all.sh`.
  - [ ] `python3 scripts/check_sdk_release_readiness.py`.
  - [ ] Wheel smoke test.
  - [ ] Sdist smoke test.

Exit gate:

- [ ] Release-readiness script passes.
- [ ] Wheel and sdist smoke tests pass from clean virtual environments.
- [ ] Trusted publisher dry-run or TestPyPI rehearsal succeeds if used.

## Milestone 9: Security, Privacy, and Operational Readiness

Goal: remove preventable release risk before v1.

Parent tasks:

- [ ] Security review.
  - [ ] No secrets in docs, fixtures, tests, dist files, or workflows.
  - [ ] Hosted tokens are never printed by CLI.
  - [ ] Error responses do not leak bearer tokens.
  - [ ] Adapter loading docs warn developers to run only trusted local code.
  - [ ] Dependency list is minimal and justified.

- [ ] Privacy review.
  - [ ] Fixtures are synthetic.
  - [ ] Docs do not encourage pasting confidential source documents into logs.
  - [ ] Hosted docs distinguish source references from large document storage.
  - [ ] Local commands do not make network requests unless explicitly hosted or verifier-related.

- [ ] Operational review.
  - [ ] Rollback/yank procedure is documented.
  - [ ] Patch-forward policy is documented.
  - [ ] Support handoff includes common install, CLI, verifier, and hosted-client failure modes.
  - [ ] Known limitations are included in release notes.

Exit gate:

- [ ] Security and privacy review checklist is complete.
- [ ] v1 release notes include known limitations and authority boundary.

## Milestone 10: Release Candidate

Goal: publish a releasable v1 candidate internally before the public v1 tag.

Parent tasks:

- [ ] Cut `1.0.0rc1`.
  - [ ] Update `pyproject.toml`.
  - [ ] Update `agevidence.__version__`.
  - [ ] Update docs where version-specific.
  - [ ] Build wheel and sdist.
  - [ ] Run wheel smoke test.
  - [ ] Run sdist smoke test.

- [ ] Run full release validation.
  - [ ] `python3 -m pytest sdks/python`.
  - [ ] `cargo test --workspace`.
  - [ ] `bash scripts/agevidence_check_all.sh`.
  - [ ] `python3 scripts/check_sdk_release_readiness.py`.
  - [ ] CLI smoke: `agevidence demo`.
  - [ ] CLI smoke: `agevidence doctor`.
  - [ ] CLI smoke: `agevidence fixture write`.
  - [ ] CLI smoke: `agevidence ingest`.
  - [ ] CLI smoke: `agevidence explain`.
  - [ ] CLI smoke: `agevidence adapter test`.
  - [ ] CLI smoke: `agevidence verify` when verifier is configured.

- [ ] Run external-developer rehearsal.
  - [ ] New virtual environment.
  - [ ] Install from built artifact.
  - [ ] Complete quickstart.
  - [ ] Build one source adapter from docs.
  - [ ] Add one CI helper test.
  - [ ] Record friction and fix blockers.

Exit gate:

- [ ] No release-blocking defects remain.
- [ ] Any deferred items are explicitly marked post-v1.

## Milestone 11: PyPI v1 GA Release

Goal: publish `agevidence==1.0.0` with a clean audit trail.

Parent tasks:

- [ ] Prepare final release.
  - [ ] Set version to `1.0.0`.
  - [ ] Update changelog or GitHub release notes.
  - [ ] Confirm docs and PyPI README mention v1 compatibility.
  - [ ] Confirm all release gates from Milestones 0 through 10 are complete.

- [ ] Build final artifacts.
  - [ ] Clean old `dist/`.
  - [ ] Build wheel.
  - [ ] Build sdist.
  - [ ] Run `twine check dist/*`.
  - [ ] Run wheel smoke test.
  - [ ] Run sdist smoke test.

- [ ] Publish.
  - [ ] Push tag `sdk-python-v1.0.0`.
  - [ ] Confirm GitHub Actions release workflow starts.
  - [ ] Approve the `pypi` environment if required.
  - [ ] Confirm PyPI publish succeeds.
  - [ ] Confirm `pip install agevidence==1.0.0` works from a clean environment.
  - [ ] Confirm `agevidence demo` works from PyPI install.

- [ ] Post-release validation.
  - [ ] Verify PyPI project page renders correctly.
  - [ ] Verify GitHub release notes and artifacts.
  - [ ] Verify docs links from PyPI.
  - [ ] Verify no accidental yanked or duplicate files.
  - [ ] Open post-v1 tracking issue for deferred work.

Exit gate:

- [ ] `agevidence==1.0.0` is installable from PyPI.
- [ ] Local-first demo, ingest, explain, adapter test, and hosted-client import work from the published package.

## Post-v1 Backlog

These items should not block v1 unless they become required by release gates.

- [ ] Additional source adapters maintained by third parties.
- [ ] More country/profile packs.
- [ ] Static documentation site generator.
- [ ] TestPyPI rehearsal automation.
- [ ] Richer provenance scoring policy.
- [ ] Machine-readable compatibility manifest.
- [ ] Plugin packaging templates.
- [ ] More hosted workflow examples.
- [ ] Offline verifier installer guidance.

## Required Commands Before Any v1 Tag

Run from the repository root:

```bash
python3 -m pytest sdks/python
cargo test --workspace
bash scripts/agevidence_check_all.sh
python3 scripts/check_sdk_release_readiness.py
```

Build and inspect package artifacts:

```bash
cd sdks/python
rm -rf dist build
python -m pip install --upgrade build twine
python -m build
python -m twine check dist/*
```

Smoke test wheel and sdist from clean virtual environments before publishing.

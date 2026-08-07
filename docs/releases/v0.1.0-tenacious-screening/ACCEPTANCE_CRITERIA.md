# Acceptance Criteria

## Phase 0: Baseline Freeze
- [x] Baseline commit 0d319350e642001a032c83bfac196a0dc3e0a90d recorded in BASELINE.md
- [x] Release branch `release/v0.1.0-tenacious-screening` created
- [x] Repository debris removed (record.json, bundle.baink.json)
- [x] Wave 2, Deferred, and Reserve work frozen until acceptance

## Phase 1: Ruby/Rails Standardization
- [x] Ruby version pinned to 3.3.12 in .ruby-version
- [x] Gemfile includes `ruby "3.3.12"` constraint
- [x] .tool-versions created with ruby 3.3.12
- [x] bin/check_runtime script added
- [ ] Rails version reconciled to 7.1 (Gemfile, Gemfile.lock, config/application.rb)
- [ ] Rails update process run and framework defaults reviewed
- [ ] Trust boundary dependency confirmed (ink_receipts gem)
- [ ] JavaScript dependencies locked (package-lock.json)
- [ ] Package name renamed to agevidence-web

## Phase 2: Repository Orchestration and CI
- [ ] Root-level orchestration scripts created (bin/setup, bin/test, bin/release_check, etc.)
- [ ] GitHub Actions workflows created (ci.yml, specs.yml, release-check.yml)
- [ ] Toolchain pinning (rust-toolchain.toml, .python-version, .node-version)

## Phase 3: Capability and Claims Truth Controls
- [ ] capabilities.yaml created with actual inventory
- [ ] schemas/capability-register.schema.json created
- [ ] scripts/capabilities/validate.rb and render.rb created
- [ ] docs/CAPABILITY_REGISTER.md generated
- [ ] docs/claims/ directory created with claim control documents

## Phase 4: Wave 1 Governance Normalization
- [ ] PROGRAM_CHARTER.md merged into CHARTER.md
- [ ] PARTICIPATION.md merged into PARTICIPATION_PATHS.md
- [ ] Wave 1/workspace.yaml created for all companies
- [ ] GitHub issue workflows created

## Phase 5: DIT Specification Workspace
- [ ] DIT AgTech workspace expanded with full specification
- [ ] Event contract, source manifest, gap register created
- [ ] Fixture coverage built
- [ ] Reliance artifact defined

## Phase 6: Rails Integration
- [ ] Reference profile models added
- [ ] Profile loader built
- [ ] DIT seed orchestration created
- [ ] Event validation implemented
- [ ] Source manifest validation implemented
- [ ] Gap projection implemented
- [ ] Append-only human review implemented
- [ ] End-to-end Rails tests added

## Phase 7: Artifact Generation and Verification
- [ ] Stable artifact manifest defined
- [ ] Artifact assembly extended
- [ ] Rails bound to Rust verifier
- [ ] Release commands created
- [ ] Tamper tests added

## Phase 8: Organization Isolation and Commercial Hardening
- [ ] Organization scoping completed for all domain models
- [ ] Organization-isolation tests added
- [ ] Role authorization hardened
- [ ] Commercial state testing completed

## Phase 9: Australia/New Zealand Boundaries
- [ ] Country-adapter status schema created
- [ ] Australian adapter hardened
- [ ] New Zealand portability demonstrated
- [ ] Enabled-impact records added

## Phase 10: MEQ Reuse Proof
- [ ] MEQ workspace structure created
- [ ] Reuse metrics documented
- [ ] Profile reuse report created

## Phase 11: Tagged Release
- [ ] Milestone status records added
- [ ] Milestone command created
- [ ] Final release check implemented
- [ ] v0.1.0-tenacious-screening tag created
- [ ] Release assets prepared

## Definition of Done
A new reviewer can clone the repository and run:
```
bin/setup
bin/release_check
```
and obtain a truthful result proving:
- Ruby 3.3.12 and Rails 7.1 are reproducible
- DIT's public hypothesis has become a machine-readable profile
- The profile runs through the real Rails evidence path
- Gaps and review decisions are preserved
- A portable artifact is generated
- The artifact verifies outside Rails
- Australia and New Zealand are profiles over one evidence graph
- Synthetic proof is not represented as customer, regulatory, revenue or climate-impact proof
- A second profile reuses the same core architecture
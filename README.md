# AgEvidence

<p align="center">
  <img src="docs/assets/agevidence-wordmark.svg" alt="AgEvidence" width="360">
</p>
<p align="center">
  <strong>Open evidence infrastructure for agricultural climate programs.</strong>
</p>
<p align="center">
  Connect operational agricultural records, identify evidence gaps, preserve
  human review, and generate portable artifacts that can be verified
  independently.
</p>
<p align="center">
  <a href="https://agevidence.com"><strong>Website</strong></a>
  •
  <a href="#open-source-design-program"><strong>Design Program</strong></a>
  •
  <a href="#quickstart"><strong>Quickstart</strong></a>
  •
  <a href="#architecture"><strong>Architecture</strong></a>
  •
  <a href="#contributing"><strong>Contributing</strong></a>
</p>
<p align="center">
  <img alt="Rails" src="https://img.shields.io/badge/Rails-7.1-CC0000">
  <img alt="Rust" src="https://img.shields.io/badge/Rust-trust_boundary-000000">
  <img alt="Python" src="https://img.shields.io/badge/Python-SDK_&_models-3776AB">
  <img alt="Architecture" src="https://img.shields.io/badge/architecture-evidence_first-2F6B57">
  <img alt="Governance" src="https://img.shields.io/badge/governance-open_design-C7D36F">
  <img alt="Status" src="https://img.shields.io/badge/status-working_prototype-C7D36F">
</p>
<p align="center">
  <img
    src="docs/assets/agevidence-workspace.png"
    alt="AgEvidence workspace showing evidence status, gaps, reviews and artifacts"
    width="100%"
  >
</p>

⸻

Overview

AgEvidence is an open source interoperability and reliance layer for
agricultural climate programs.

It does not replace farm-management systems, sensors, laboratories, model
providers, project developers, registries, verifiers, or assurance platforms.
It connects records from those systems into portable evidence structures that
institutions can inspect, review, and verify.

Connect	Resolve	Rely
Ingest signed events or controlled source records.	Detect missing evidence and preserve human review.	Generate bounded artifacts for named institutional uses.

AgEvidence separates:

* direct observation from model interpretation;
* source records from derived claims;
* automated processing from human determination;
* evidence preservation from country- or program-specific rules;
* hosted workflow from independent verification.

⸻

Open source design program

AgEvidence is developed through public specifications, synthetic reference
cases, working implementations, and open design review.

The project maintains an Open Source Design Advisory Board to help ensure
that its schemas and workflows reflect real agricultural technology,
measurement, assurance, and program operations.

The advisory board may include:

* agricultural technology practitioners;
* scientists and methodology experts;
* software and data engineers;
* project developers;
* assurance and verification professionals;
* producers and program operators;
* institutional evidence users;
* open source contributors.

Participation is advisory and voluntary. Maintainers remain responsible for
repository decisions, releases, security, and technical direction.

What advisors and contributors review

The design process focuses on:

* operational event contracts;
* controlled source manifests;
* identity and authority records;
* calibration and measurement provenance;
* evidence-gap taxonomies;
* human-review semantics;
* country and program adapters;
* reliance-artifact boundaries;
* independent verification;
* privacy-preserving integration patterns.

Participation does not imply

Participation does not create:

* a customer or vendor relationship;
* a paid design-partner relationship;
* an obligation to purchase or deploy AgEvidence;
* an obligation to provide proprietary or customer data;
* organizational endorsement;
* exclusivity;
* transfer of intellectual property beyond accepted open source contributions.

See:

* Wave 1/CHARTER.md⁠￼
* Wave 1/PARTICIPATION.md⁠￼
* Wave 1/REFERENCE_CASE_POLICY.md⁠￼
* CONTRIBUTING.md⁠￼

⸻

Wave 1 — Event-First Systems Working Group

Wave 1 develops open evidence profiles for agricultural technologies that
produce operational records through devices, sensors, software platforms,
measurement systems, or remote-observation systems.

The working group asks:

Can one bounded operational workflow be represented as a portable evidence
contract without overstating what the underlying system directly proves?

Public reference cases

Wave 1 currently contains public-information reference cases based on:

* Agronomeye
* Agscent
* Cibo Labs
* DIT AgTech
* MEQ Solutions

These folders are design workspaces, not company dossiers, customer accounts,
or implementation commitments.

Unless a workspace explicitly states otherwise:

* the organization has not joined the advisory board;
* the organization has not reviewed the workspace;
* the organization is not affiliated with AgEvidence;
* the organization does not endorse AgEvidence;
* the design case is based on public information;
* all example records and fixtures are synthetic.

Each organization is invited to correct inaccurate terminology, identify
invalid assumptions, recommend safer data boundaries, and review how its
product category is represented.

What each reference case should contain

A complete Wave 1 case includes:

1. a public system hypothesis;
2. one representative evidence flow;
3. a draft event contract;
4. a controlled source-manifest example;
5. an open-question register;
6. an evidence-gap taxonomy;
7. a proposed reliance-artifact specification;
8. synthetic fixtures;
9. conformance expectations;
10. recorded architecture decisions.

Browse the working group:

Wave 1/Cohort A - Event-First⁠￼

Reference-case maturity

Stage	Meaning
Hypothesis	Public-information draft with no company review
Community reviewed	Reviewed by independent contributors
Advisor reviewed	Reviewed by someone with relevant domain expertise
Specification candidate	Schemas, fixtures and expected outputs are defined
Reference implementation	The profile runs through AgEvidence end to end
Adopted profile	Tested by more than one independent implementation

⸻

How AgEvidence works

flowchart LR
    A[Farm and program systems] --> B[Evidence Event Inbox]
    A --> C[Controlled source records]
    B --> D[Evidence Graph]
    C --> D
    D --> E[Evidence Gap Analyzer]
    E --> F[Human Review Ledger]
    F --> G[Country and program adapters]
    G --> H[Reliance Artifacts]
    H --> I[Independent verification]

Core design principle

AgEvidence preserves a stable evidence layer beneath changing methodologies,
program rules, country requirements, and institutional interpretations.

The same underlying evidence graph can therefore be evaluated through
different versioned adapters without rewriting or duplicating the original
records.

⸻

Product surfaces

Surface	Purpose
AgEvidence Workspace	Inspect projects, source records, gaps, reviews and outputs
Evidence Event Inbox	Receive append-only signed events from upstream systems
Controlled Source Records	Register files and exports when native event integration is unavailable
Evidence Gap Analyzer	Identify missing, conflicting or unsupported evidence
Human Review Ledger	Preserve determinations, exceptions, overrides and unresolved questions
Developer OS	Create projects and integrate through APIs, SDKs and webhooks
Country Programs	Interpret one evidence graph through versioned local adapters
Reliance Artifacts	Produce bounded outputs for buyers, verifiers and program operators
Portable Verification	Verify released artifacts outside the hosted application

⸻

Working demonstration

Australian Beef Pilot

The seeded demonstration follows one synthetic agricultural climate project
through:

1. operational event and source-record intake;
2. evidence projection;
3. model execution;
4. evidence-gap detection;
5. human review;
6. reliance-artifact generation;
7. independent verification;
8. methodology-version comparison.

The demonstration uses synthetic data. Sandbox prices, orders, model outputs,
reference companies, and example artifacts are not represented as booked
revenue, certified claims, production determinations, endorsements, or
operational partnerships.

⸻

Quickstart

Run the workspace

cd athian_ink_rails_bootstrap
bin/setup
bin/rails db:migrate db:seed
npm run build
bin/dev

Open:

http://localhost:3000/agevidence
<details>
<summary><strong>Run the Python model service</strong></summary>
cd services/agevidence-model
python3 -m pytest
</details>
<details>
<summary><strong>Install the Python SDK and CLI</strong></summary>
cd sdks/python
python3 -m pip install -e .
agevidence --help
</details>
<details>
<summary><strong>Build the verifier</strong></summary>
cargo test --workspace
cargo build -p baink-cli
</details>

⸻

Developer OS

from agevidence import AgEvidence
client = AgEvidence(
    base_url="http://localhost:3000",
    api_key="agev_test_local",
)
project = client.projects.create(
    name="Australian Beef Pilot",
    country="AU",
)
project.source_records.create(
    source_type="livestock_activity",
    uri="s3://example/activity-record.json",
)
quote = project.artifacts.quote(
    product="verification_bundle",
)
print(quote.verification_command)

⸻

Architecture

apps
• Rails workspace and human review
services
• Evidence-model service
sdks
• Python and TypeScript developer clients
specs
• Evidence contracts, reference profiles and country adapters
crates
• Canonicalization, receipts, bundles and verification
Wave 1
• Public design cases, synthetic fixtures and open specifications

Trust boundary

The hosted Rails application presents workflow state and coordinates human
review. It does not directly perform canonical hashing, signing, bundling, or
independent verification.

Those operations remain behind the released receipt and verifier boundary.

<details>
<summary><strong>Trust-boundary operations</strong></summary>
InkReceipts.issue(...)
InkReceipts.verify(...)
InkReceipts.bundle(...)
InkReceipts.attest(...)
InkReceipts.export(...)
InkReceipts.migrate(...)
InkReceipts.graph(...)
InkReceipts.verify_bundle(...)
</details>

⸻

Open specifications

AgEvidence specifications should be:

* implementation-neutral where practical;
* explicit about direct observations and derived interpretations;
* bounded in the claims they support;
* versioned;
* testable with synthetic fixtures;
* independently verifiable;
* reusable across companies and jurisdictions.

Useful specification contributions include:

* event-contract schemas;
* source-manifest formats;
* authority and identity records;
* calibration and provenance records;
* gap classifications;
* review and override semantics;
* reliance-artifact profiles;
* country and methodology adapters;
* conformance fixtures.

⸻

Design decisions

Material architecture decisions should be documented through issues, pull
requests, and architecture decision records.

A design decision should record:

* the problem being addressed;
* relevant reference cases;
* alternatives considered;
* advisor and contributor input;
* the selected approach;
* known limitations;
* implementation consequences.

Advisory feedback informs decisions but does not replace maintainer
responsibility.

⸻

Project status

Capability	Status
Rails evidence workspace	Working prototype
Signed event intake	Working
Controlled source-record path	Working
Evidence-gap projection	Working
Human review ledger	Working
Python SDK and CLI	Working
Model-service integration	Fixture-backed
Artifact ordering	Sandbox
Country adapters	Scaffolded
Wave 1 reference cases	Initial hypotheses
Open advisory governance	In development
Production certification	Not complete

⸻

Roadmap

Product

* Evidence Event Inbox
* Controlled source-record path
* Evidence-gap projections
* Human review ledger
* Python SDK and CLI
* Sandbox artifact orders
* Hosted public demonstration
* TypeScript SDK package
* Australian program-adapter validation
* External verifier review
* Production identity and access controls

Open design program

* Publish advisory-board charter
* Publish reference-case and attribution policies
* Complete the Wave 1 shared event taxonomy
* Build one canonical event-first reference profile
* Add synthetic fixtures and conformance tests
* Record architecture decisions
* Invite independent domain reviewers
* Advance the first case to specification-candidate status
* Implement the first profile end to end
* Test one profile across multiple independent systems

⸻

Contributing

AgEvidence welcomes contributions from developers, agricultural practitioners,
scientists, program operators, assurance professionals, and institutional
evidence users.

You do not need to join the advisory board to contribute.

Ways to participate

Review a reference case

* correct terminology;
* identify an invalid assumption;
* answer an open design question;
* identify a missing evidence record;
* recommend a safer data boundary.

Contribute technical work

* propose or review a schema;
* add synthetic fixtures;
* implement an adapter;
* add conformance tests;
* improve SDKs or documentation;
* review portable verification behavior.

Participate as a design advisor

Design advisors may participate as individuals or, with explicit permission, as
representatives of an organization.

Advisors can:

* review product-category assumptions;
* participate in asynchronous design discussions;
* review specification candidates;
* contribute domain requirements;
* help evaluate interoperability tradeoffs.

Listing as a contributor or advisor indicates participation only. It does not
imply endorsement, adoption, certification, or commercial affiliation.

See CONTRIBUTING.md⁠￼ before opening a pull request.

⸻

Reference-case corrections

AgEvidence aims to represent public reference organizations accurately and
fairly.

An organization or individual may open an issue or submit a pull request to:

* correct inaccurate public information;
* request changes to terminology;
* clarify a system boundary;
* identify an unsupported inference;
* request attribution changes;
* request removal of an inaccurate representation.

Corrections should be documented transparently whenever possible.

⸻

Security

Do not report security vulnerabilities through public GitHub issues.

See SECURITY.md⁠￼.

Do not submit:

* credentials;
* proprietary customer records;
* personal information;
* production datasets;
* confidential system details;
* restricted methodology materials.

Use synthetic, redacted, or structurally representative examples for public
design work.

⸻

License

See LICENSE⁠￼.

Open source licensing applies to repository content according to the applicable
license. Participation in design review does not automatically transfer
ownership of pre-existing company technology, proprietary models, confidential
information, trademarks, or data.

The most important edits are the new Open source design program, Wave 1 working group, reference-case disclaimer, maturity model, and the separation between advisory participation and organizational endorsement.
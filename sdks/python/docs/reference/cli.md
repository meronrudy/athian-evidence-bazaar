# CLI Reference

## Local-first Commands

```bash
agevidence demo
agevidence doctor
agevidence fixture list
agevidence fixture write livestock-weight --out ./livestock-weight.json
agevidence ingest ./livestock-weight.json --format table
agevidence explain ./livestock-weight.json --format table
```

These commands do not require an Agevidence account, API key, Rails app, hosted
service, or network request.

## Source Adapter Commands

```bash
agevidence adapter test my_adapter.py fixtures/
agevidence adapter test my_adapter.py:MyAdapter fixtures/
agevidence adapter test my_package.adapters:MyAdapter fixtures/
```

`adapter` is singular and means source-system mapping adapter.

## Country/Profile Adapter Commands

```bash
agevidence adapters list
agevidence adapters show AU
agevidence adapters validate AU
agevidence identifiers normalize AU au_pic ABC123
agevidence sources normalize AU au_envd record.json
```

`adapters` is plural and means country/profile adapters.

## Verification

```bash
agevidence verify bundle.json
```

Verification is delegated to the configured Rust verifier.

## Hosted Commands

Hosted commands require configured hosted infrastructure:

```bash
agevidence login --base-url http://localhost:3000
agevidence project create --account-name "Startup" --name "Pilot" --target-claim "Methane reduction"
agevidence source add --project-id PROJECT_ID --document-id trial-report-001 --evidence-type evidence.trial_report --controlled-uri evidence://trial-report-001 --commitment sha256:demo
agevidence model run --project-id PROJECT_ID
```

Hosted workflows are optional. They should not be required for local evidence
work.

## PASS Boundary

Any local `PASS` reports structure, provenance, lineage, deterministic
representation, or contract compatibility. It does not establish regulatory
eligibility, scientific validity, carbon-credit issuance, third-party
verification, claim ownership, or institutional reliance.


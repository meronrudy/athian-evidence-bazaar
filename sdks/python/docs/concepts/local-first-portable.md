# Local-first and Portable

Core SDK operations are designed to work without:

- an Agevidence account;
- an API key;
- a hosted service;
- a Rails deployment;
- an internet connection.

## Local Commands

```bash
agevidence demo
agevidence doctor
agevidence fixture list
agevidence fixture write livestock-weight --out ./livestock-weight.json
agevidence ingest ./livestock-weight.json --format table
agevidence explain ./livestock-weight.json --format table
```

## Portability Promise

You are adopting a format and toolchain, not locking evidence into a SaaS
product.

An Agevidence-compatible artifact should be inspectable by independent tools.
Hosted services can add managed infrastructure, identity, review, retention,
and institutional APIs, but local evidence should remain useful without them.

Local `PASS` does not establish regulatory eligibility, scientific validity,
carbon-credit issuance, third-party verification, claim ownership, or
institutional reliance.


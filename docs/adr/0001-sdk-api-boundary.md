# ADR 0001: SDK/API Boundary

Status: Accepted

The `sdks/python` package remains the canonical AgEvidence SDK and CLI. It may orchestrate Developer OS HTTP APIs, adapter execution, fixture replay, and verifier delegation, but it must not issue receipts or mutate Rails-only workflow state except through `/v1` API calls.

The Rails `/v1` API is the boundary for persisted projects, source records, model runs, reviews, country determinations, artifact orders, integration events, and operations.


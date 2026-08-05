# Pricing, Orders, and Artifacts Guide

This guide explains the sandbox commercial path from quote to artifact.

Sandbox pricing and orders are illustrative planning records, not booked,
collected, or recognized revenue.

## Product Catalog

Products are loaded from the repository price-book configuration. Use:

```text
GET /v1/pricing/products
```

Initial product concepts include:

- Evidence Architecture Sprint
- Protocol Evidence Implementation
- Verification Readiness Cycle
- Enterprise Reliance Artifact
- Managed Evidence Plane
- Private Deployment Model Registry
- Sponsor Portfolio Program
- Methodology Migration or Dispute Event

These are planning products for the scaffold. They are not standard market
quotes or recognized revenue.

## Pricing Basis

Artifact value is based on evidence and reliance complexity:

- base product
- protocol complexity
- evidence-class count
- source-system count
- review burden
- country-policy count
- relying-party count
- selective-disclosure requirements
- turnaround requirement
- migration or dispute exposure

Do not price institutional artifacts primarily by token usage, signature count,
receipt count, raw bytes, or API-call volume.

## Quote Flow

```text
POST /v1/pricing/quotes
GET  /v1/pricing/quotes/:id
```

A quote preserves the product code, versioned pricing input, breakdown,
expiration, and customer/project context.

## Order Flow

```text
POST /v1/artifact-orders
GET  /v1/artifact-orders/:id
POST /v1/artifact-orders/:id/checkout
```

Sandbox checkout changes order state only inside the scaffold. It does not
collect payment or create recognized revenue.

## Artifact Flow

```text
POST /v1/developer/projects/:project_id/artifacts
GET  /v1/developer/projects/:project_id/artifacts/:id
GET  /v1/developer/projects/:project_id/artifacts/:id/download
```

Artifact metadata should show:

- bundle status
- receipt root
- verification status
- limitations
- download path or metadata
- local verification command

## Status Boundaries

An artifact page must distinguish:

- `integrity_status`
- `policy_compatibility`
- `review_status`
- `artifact_status`
- `reliance_status`
- `payment_status`

Payment success does not prove artifact validity. Artifact validity does not
prove institutional reliance.

## Related Guides

- [API User Guide](API_USER_GUIDE.md)
- [Local Verification Guide](LOCAL_VERIFICATION_GUIDE.md)
- [Webhook and Operations Guide](WEBHOOKS_OPERATIONS_GUIDE.md)

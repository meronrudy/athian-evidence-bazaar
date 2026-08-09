# Commercial Order Lifecycle Architecture

## Overview

This document describes the commercial order lifecycle architecture for the Agevidence platform, focusing on the reconciliation of the two parallel fulfillment paths and the unified commercial order processing flow.

## Current State (Pre-Reconciliation)

There were two competing implementations of order fulfillment:

### Legacy Path (Browser)
- **Controller**: `Agevidence::ArtifactOrdersController` (browser, `/agevidence/...`)
- **Checkout**: `order.checkout!` (model method, deprecated)
- **Fulfillment**: `Agevidence::ArtifactOrderFulfillment.new(order:).call`
  - Creates `Protocol`/`Avsa` scaffold if missing
  - Creates `ArtifactEngagement`
  - Calls `ArtifactAssembler`
  - Sets metadata (`receipt_root`, `verification_command`, `integrity_status`, `reliance_status`)
  - Dispatches webhook via `Integrations::WebhookDispatcher`
- **State transition ledger**: Not recorded (no `Commercial::OrderEvent` writes)

### New Path (API)
- **Controller**: `V1::ArtifactOrdersController` (API, `/v1/...`)
- **Checkout**: `Commercial::Orders::MarkPaid.call(order)`
- **Fulfillment**: `Commercial::Orders::BeginFulfillment` + `Commercial::Orders::Fulfill`
  - **Status flips only** - no engagement creation, artifact assembly, metadata setting, or webhook dispatch
- **State transition ledger**: `Commercial::OrderEvent.record_transition!` on every step

## Reconciliation Decision

**Target Architecture**: `Commercial::Orders::*` remains the canonical entry point. The real fulfillment work from `ArtifactOrderFulfillment` is moved into `Commercial::Orders::BeginFulfillment` and `Commercial::Orders::Fulfill`.

## Unified Commercial Order Flow

### Order Creation
1. `Commercial::Orders::Create` - Creates order with status "quoted"
2. `Commercial::OrderEvent.record_transition!` with event_type "create"

### Payment Processing
1. `Commercial::Orders::MarkPaid` - Transitions to "paid"
2. `Commercial::OrderEvent.record_transition!` with event_type "mark_paid"

### Fulfillment Workflow
1. `Commercial::Orders::BeginFulfillment` - Guards on `order.status == "paid"`, creates engagement, transitions to "assembling"
2. `Commercial::Orders::Fulfill` - Calls `ArtifactAssembler`, sets engagement/bundle/metadata, dispatches webhook, transitions to "fulfilled"
3. Both services record transitions via `Commercial::OrderEvent.record_transition!`

### Error Handling
- During assembly, if `StandardError` occurs, order lands in "verification_pending" with `metadata_json["last_error"]` set
- Full `Commercial::OrderEvent` audit trail maintained for all transitions

## State Transition Graph

```
quoted → checkout_pending → paid → assembling → verification_pending → fulfilled
                     ↘ canceled/expired ↗
                     ↘ payment_failed ↗
```

## Services

### Core Services
- `Commercial::Orders::Create` - Order creation
- `Commercial::Orders::MarkPaid` - Payment confirmation
- `Commercial::Orders::BeginFulfillment` - Start fulfillment workflow
- `Commercial::Orders::Fulfill` - Complete artifact assembly and delivery

### Supporting Services
- `Commercial::Orders::Authorize` - Payment authorization (future)
- `Commercial::Orders::Cancel` - Order cancellation (future)
- `Commercial::Orders::Refund` - Order refund (future)

### Infrastructure Services
- `Commercial::OrderEvent` - Append-only transition ledger
- `Commercial::Money` - Currency formatting/validation
- `Agevidence::ProductCatalog` - Product configuration
- `Agevidence::PricingEngine` - Pricing logic
- `Agevidence::DeveloperOsAvsaBootstrap` - Protocol/AVSA scaffold creation (new)

## Controller Integration

### Browser Controller (`Agevidence::ArtifactOrdersController`)
- `create` → `Commercial::Orders::Create`
- `checkout` → `Commercial::Orders::MarkPaid`
- `assemble` → `Commercial::Orders::BeginFulfillment` → `Commercial::Orders::Fulfill`

### API Controller (`V1::ArtifactOrdersController`)
- `create` → `Commercial::Orders::Create`
- `checkout` → `Commercial::Orders::MarkPaid`
- `assemble` → `Commercial::Orders::BeginFulfillment` → `Commercial::Orders::Fulfill`

## Transition Guards

Every service validates legal transitions using a centralized graph:

```ruby
Commercial::Orders::TRANSITIONS = {
  "quoted" => %w[checkout_pending canceled expired],
  "checkout_pending" => %w[paid payment_failed canceled expired],
  "paid" => %w[assembling canceled],
  "assembling" => %w[verification_pending fulfilled],
  "verification_pending" => %w[fulfilled],
  "fulfilled" => %w[refunded]
}.freeze
```

## Revenue Recognition Separation

Fulfillment (technical completion) and revenue recognition (financial completion) are represented by different records:

- **Fulfillment**: `ArtifactOrder.status` transitions through fulfillment states
- **Revenue Recognition**: Separate `Commercial::RevenueRecognition` model/table (future)

## Organization Scoping

All commercial models are organization-scoped:

- `Commercial::OrderEvent` - `organization_id` derived from `order.developer_project.organization_id`
- `ArtifactOrder`, `ArtifactEngagement`, `PricingQuote` - Already organization-scoped per repo-wide Phase 8

## Authorization

Billing-relevant actions require role checks:

- `MarkPaid`, `Authorize`, `Cancel`, `Refund` require `billing_manager` or `owner`/`administrator` role
- Actions recorded with `actor:` in `Commercial::OrderEvent`

## Testing

- `test/services/commercial/orders/` contains one test file per service
- Reconciliation regression tests ensure both controllers produce equivalent ledgers
- Organization isolation tests for commercial models

## Exit Criteria

- Exactly one fulfillment implementation exists (`Commercial::Orders::*`)
- `ArtifactOrderFulfillment` and `ArtifactOrder#checkout!` are deleted
- Both controllers route through same services
- Complete `Commercial::OrderEvent` audit trail for all orders
- All legal transitions explicitly defined and enforced
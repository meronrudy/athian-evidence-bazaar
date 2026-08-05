puts "Resetting Athian Evidence Bazaar demo data..."

[
  Campaign::CapabilityAttribution,
  Campaign::ConnectorOutbox,
  Campaign::CommercialHandoff,
  Campaign::TechnicalQualification,
  Campaign::Touch,
  Campaign::ActivationPath,
  Campaign::ContactRef,
  Campaign::AdapterReadinessAssessment,
  Campaign::ObligationProfile,
  Campaign::InstitutionProfile,
  Campaign::CountryProgram,
  Campaign::Account,
  Agevidence::SourceRecord,
  IntegrationDelivery,
  IntegrationWebhookEndpoint,
  ReceiptOutbox,
  EvidenceProjection,
  ExternalObjectMapping,
  IntegrationOperation,
  IntegrationEvent,
  IntegrationSource,
  Agevidence::RelianceEvent,
  Agevidence::ReviewDecision,
  Agevidence::EvidenceGap,
  Agevidence::EvidenceCandidate,
  Agevidence::CountryDetermination,
  Agevidence::ArtifactOrder,
  Agevidence::PricingQuote,
  Agevidence::ModelRun,
  Agevidence::ArtifactEngagement,
  Agevidence::DeveloperProject,
  Agevidence::DeveloperAccount,
  Agevidence::ModelAdapter,
  EvidenceBundle,
  Agevidence::CountryAdapter,
  Agevidence::CountryRegistry,
  Agevidence::CountryPilot,
  Agevidence::CountryInstitution,
  Agevidence::CountryDataPolicy,
  Agevidence::CountryVerificationProfile,
  Agevidence::CountryClaimPolicy,
  Agevidence::CountryMethodVersion,
  Agevidence::CountryMethod,
  Agevidence::CountryProgram,
  MethodologyMigration,
  VerificationException,
  VerificationRun,
  EvidenceItem,
  ClaimShare,
  ClaimGroup,
  ProducerPayment,
  Receipt,
  Avsa,
  Protocol
].each(&:delete_all)

now = Time.utc(2026, 8, 4, 16, 30, 0)

IntegrationSource.create!(
  key: "athian_salesforce_production",
  name: "Synthetic Athian Salesforce Production",
  environment: "synthetic_demo",
  signature_algorithm: "hmac_sha256",
  verification_secret_ciphertext: "project-4030-demo-secret",
  allowed_event_types: Integrations::EventRegistry::EVENT_TYPES.keys,
  metadata_json: {
    authority_boundary: "Upstream platform remains authoritative for operational records.",
    fixture_path: "examples/integrations/project_4030_beef"
  }
)

commitment = lambda do |label|
  InkReceipts.issue(
    payload: { seed_label: label.to_s },
    issuer: "Athian Demo Seed",
    receipt_type: "seed_commitment",
    schema: "athian.seed_commitment.v1"
  ).fetch(:body_digest)
end

feed_protocol = Protocol.create!(
  code: "VM0042",
  name: "Livestock Enteric Methane Reduction",
  version: "v2.2",
  governance_version: "ATH-GOV-2026.1",
  status: "active",
  effective_on: Date.new(2026, 1, 1),
  description: "Seeded protocol for the evidence-first AVSA receipt chain."
)

review_protocol = Protocol.create!(
  code: "ATH-LI-CH4-REVIEW",
  name: "Annual Review Methane Pilot",
  version: "v0.9",
  governance_version: "ATH-GOV-2026.1",
  status: "annual_review",
  effective_on: Date.new(2026, 4, 1),
  description: "Secondary protocol used to surface verifier failure states."
)

canonical_avsa = Avsa.create!(
  protocol: feed_protocol,
  external_id: "AVSA-DEMO-2026-0001",
  title: "Great Lakes Dairy Feed Intervention",
  producer_name: "Maple Ridge Dairy Cooperative",
  intervention_provider: "Northstar Feed Systems",
  vvb_name: "Independent Carbon Assurance LLC",
  buyer_name: "Common Table Foods",
  status: "finalized",
  verified_quantity: 1_250.000,
  unit: "tCO2e",
  started_on: Date.new(2026, 1, 15),
  reporting_period: "2026-Q1 through 2026-Q2",
  local_verification_status: "valid",
  methodology_name: "VM0042",
  methodology_version: "v2.2"
)

create_receipt = lambda do |avsa:, type:, title:, lifecycle:, domain:, issuer:, sequence:, parents:, schema:, status:, evidence:|
  issued = InkReceipts.issue(
    payload: {
      avsa: avsa.external_id,
      title: title,
      receipt_type: type,
      domain_state: domain,
      sequence: sequence,
      evidence: evidence.map { |item| item.fetch(:name) }
    },
    issuer: issuer,
    receipt_type: type,
    schema: schema,
    parents: parents.map(&:body_digest),
    lifecycle: lifecycle,
    avsa: avsa.external_id,
    signer: "did:key:athian-demo-#{sequence}"
  )

  receipt = avsa.receipts.create!(
    receipt_type: type,
    title: title,
    lifecycle_state: lifecycle,
    domain_state: domain,
    issuer_name: issuer,
    signer_key_id: issued.fetch(:signer_key_id),
    schema_id: issued.fetch(:schema_id),
    schema_digest: issued.fetch(:schema_digest),
    body_digest: issued.fetch(:body_digest),
    evidence_commitment: issued.fetch(:evidence_commitment),
    policy_commitment: issued.fetch(:policy_commitment),
    trace_commitment: issued.fetch(:trace_commitment),
    sequence: sequence,
    parent_receipt_ids: parents.map(&:id),
    canonical_encoding_hex: issued.fetch(:canonical_encoding_hex),
    integrity_status: status,
    signed_at: now - (12 - sequence).hours,
    sealed_at: lifecycle == "sealed" ? now - (11 - sequence).hours : nil
  )

  evidence.each_with_index do |item, index|
    receipt.evidence_items.create!(
      name: item.fetch(:name),
      evidence_type: item.fetch(:type),
      source_system: item.fetch(:source),
      commitment: commitment.call("#{avsa.external_id}:#{type}:#{index}:#{item.fetch(:name)}"),
      disclosure_status: item.fetch(:disclosure),
      required: item.fetch(:required, true),
      status: item.fetch(:status, "present"),
      captured_at: item.fetch(:status, "present") == "present" ? now - (20 - sequence).days : nil,
      metadata: {
        retention_class: item.fetch(:disclosure) == "public" ? "public_permanent" : "controlled_7_year",
        source_owner: item.fetch(:source).humanize
      }
    )
  end

  receipt
end

receipts = []
[
  {
    type: "practice_receipt",
    title: "Practice Receipt",
    domain: "producer_implemented_intervention",
    issuer: "Northstar Feed Systems",
    schema: "athian.practice_receipt.v1",
    evidence: [
      { name: "Feed Invoice", type: "feed_invoice", source: "supplier_erp", disclosure: "selective" },
      { name: "GPS Data", type: "gps_data", source: "field_activity_log", disclosure: "restricted" }
    ]
  },
  {
    type: "measurement_receipt",
    title: "Measurement Receipt",
    domain: "source_measurements_recorded",
    issuer: "Athian Measurement Operations",
    schema: "athian.measurement_receipt.v1",
    evidence: [
      { name: "Lab Report", type: "lab_report", source: "accredited_lab", disclosure: "selective" },
      { name: "Satellite Image", type: "satellite_image", source: "remote_sensing", disclosure: "public" }
    ]
  },
  {
    type: "model_execution_receipt",
    title: "Model Execution Receipt",
    domain: "reductions_quantified",
    issuer: "Athian Quantification",
    schema: "athian.model_execution_receipt.v1",
    evidence: [
      { name: "Model Run", type: "model_run", source: "athian_calculator", disclosure: "public" }
    ]
  },
  {
    type: "verifier_receipt",
    title: "Verifier Receipt",
    domain: "vvb_attested",
    issuer: "Independent Carbon Assurance LLC",
    schema: "athian.verifier_receipt.v1",
    evidence: [
      { name: "VVB Determination", type: "vvb_determination", source: "vvb_console", disclosure: "selective" }
    ]
  },
  {
    type: "issuance_receipt",
    title: "Issuance Receipt",
    domain: "avsa_issued",
    issuer: "Athian Certification",
    schema: "athian.issuance_receipt.v1",
    evidence: [
      { name: "Registry Record", type: "registry_record", source: "athian_registry", disclosure: "public" }
    ]
  },
  {
    type: "claim_receipt",
    title: "Claim Receipt",
    domain: "scope_3_claim_recorded",
    issuer: "Athian Claim Custody",
    schema: "athian.claim_receipt.v1",
    evidence: [
      { name: "Claimant Contribution Schedule", type: "claim_schedule", source: "finance_ledger", disclosure: "restricted" }
    ]
  },
  {
    type: "producer_payment_receipt",
    title: "Producer Payment Receipt",
    domain: "producer_paid",
    issuer: "Athian Finance",
    schema: "athian.producer_payment_receipt.v1",
    evidence: [
      { name: "Payment Advice", type: "payment_advice", source: "banking_connector", disclosure: "selective" }
    ]
  }
].each_with_index do |definition, index|
  receipts << create_receipt.call(
    avsa: canonical_avsa,
    type: definition.fetch(:type),
    title: definition.fetch(:title),
    lifecycle: "sealed",
    domain: definition.fetch(:domain),
    issuer: definition.fetch(:issuer),
    sequence: index + 1,
    parents: index.zero? ? [] : [receipts.last],
    schema: definition.fetch(:schema),
    status: "valid",
    evidence: definition.fetch(:evidence)
  )
end

contribution_receipt = create_receipt.call(
  avsa: canonical_avsa,
  type: "contribution_receipt",
  title: "Contribution Receipt",
  lifecycle: "sealed",
  domain: "co_claim_contributions_bound",
  issuer: "Athian Claim Custody",
  sequence: 8,
  parents: [receipts[5]],
  schema: "athian.contribution_receipt.v1",
  status: "valid",
  evidence: [
    { name: "Contribution Allocation", type: "claim_schedule", source: "finance_ledger", disclosure: "restricted" }
  ]
)

retirement_receipt = create_receipt.call(
  avsa: canonical_avsa,
  type: "retirement_receipt",
  title: "Retirement Receipt",
  lifecycle: "sealed",
  domain: "scope_3_claim_retired",
  issuer: "Athian Claim Custody",
  sequence: 9,
  parents: [contribution_receipt],
  schema: "athian.retirement_receipt.v1",
  status: "valid",
  evidence: [
    { name: "Retirement Ledger Record", type: "registry_record", source: "emissions_ledger", disclosure: "public" }
  ]
)

migration_issued = InkReceipts.migrate(
  avsa: InkProjection.avsa(canonical_avsa),
  old_methodology: { name: "VM0042", version: "v2.2" },
  new_methodology: { name: "VM0042", version: "v3.0" },
  affected_credits: canonical_avsa.verified_quantity,
  impact: "Recalculation lowers recognized reductions by 2.1% while preserving the original chain."
)

delta_receipt = canonical_avsa.receipts.create!(
  receipt_type: migration_issued.fetch(:receipt_type),
  title: migration_issued.fetch(:title),
  lifecycle_state: migration_issued.fetch(:lifecycle_state),
  domain_state: "methodology_migration_appended",
  issuer_name: migration_issued.fetch(:issuer),
  signer_key_id: migration_issued.fetch(:signer_key_id),
  schema_id: migration_issued.fetch(:schema_id),
  schema_digest: migration_issued.fetch(:schema_digest),
  body_digest: migration_issued.fetch(:body_digest),
  evidence_commitment: migration_issued.fetch(:evidence_commitment),
  policy_commitment: migration_issued.fetch(:policy_commitment),
  trace_commitment: migration_issued.fetch(:trace_commitment),
  sequence: 10,
  parent_receipt_ids: [retirement_receipt.id],
  canonical_encoding_hex: migration_issued.fetch(:canonical_encoding_hex),
  integrity_status: migration_issued.fetch(:integrity_status),
  signed_at: now,
  sealed_at: now
)

canonical_avsa.update!(root_digest: commitment.call(canonical_avsa.receipts.order(:sequence).map(&:body_digest).join("|")))

claim_group = canonical_avsa.create_claim_group!(
  name: "Great Lakes Dairy 2026 Scope 3 Co-Claim Group",
  verified_total: canonical_avsa.verified_quantity,
  unit: canonical_avsa.unit,
  aggregate_cap_percent: 100,
  finalization_status: "draft",
  prior_claim_check_status: "passed",
  retirement_status: "valid",
  exclusivity_status: "valid"
)

[
  ["Producer", "Producer", 60.0, 120_000, "Scope 3 Category 1"],
  ["Feed Company", "Intervention provider", 15.0, 30_000, "Scope 3 Category 1"],
  ["Processor", "Processor", 20.0, 40_000, "Scope 3 Category 1"],
  ["Brand", "Consumer packaged goods", 5.0, 10_000, "Scope 3 Category 1"]
].each_with_index do |(name, role, share, contribution, category), index|
  claim_group.claim_shares.create!(
    claimant_name: name,
    claimant_role: role,
    share_percent: share,
    contribution_amount: contribution,
    inventory_category: category,
    contract_right_digest: commitment.call("contract-right:#{index}:#{name}"),
    status: "proposed"
  )
end

canonical_avsa.create_producer_payment!(
  producer_name: canonical_avsa.producer_name,
  gross_amount: 200_000,
  verification_deduction: 25_000,
  platform_deduction: 25_000,
  other_deductions: 0,
  net_amount: 150_000,
  currency: "USD",
  status: "remitted",
  remittance_reference: "ACH-2026-0001",
  paid_at: now - 1.hour
)

canonical_avsa.methodology_migrations.create!(
  delta_receipt: delta_receipt,
  old_methodology: "VM0042",
  old_version: "v2.2",
  new_methodology: "VM0042",
  new_version: "v3.0",
  status: "impact_review",
  affected_credits: canonical_avsa.verified_quantity,
  impact_summary: "Recalculation lowers recognized reductions by 2.1% while preserving the original chain.",
  recalculation_payload: migration_issued,
  appended_at: now
)

manifest = BundleManifestBuilder.new(avsa: canonical_avsa, bundle_type: "buyer").call
canonical_avsa.evidence_bundles.create!(
  bundle_type: "buyer",
  name: manifest.fetch(:bundle_name),
  audience: manifest.fetch(:audience),
  problem: manifest.fetch(:problem),
  status: "generated",
  artifact_filename: "avsa-demo-2026-0001-buyer.zip",
  artifact_path: "tmp/exports/avsa-demo-2026-0001-buyer.zip",
  verification_status: "valid",
  manifest: manifest,
  generated_at: now
)

source_receipt = receipts[2]
[
  ["Northstar Trial Report", "trial_report", "trial-report-001", "evidence.animal_cohort"],
  ["Northstar Product Invoice", "feed_invoice", "invoice-001", "evidence.intervention_delivery"],
  ["Northstar Ration Log", "ration_log", "ration-log-001", "evidence.feed_record"],
  ["Northstar Measurement Export", "measurement_export", "measurement-export-001", "evidence.weight_record"]
].each do |name, type, document_id, global_evidence_type|
  source_receipt.evidence_items.create!(
    name: name,
    evidence_type: type,
    source_system: "northstar_methane_systems",
    commitment: commitment.call("northstar:#{document_id}"),
    disclosure_status: "restricted",
    required: true,
    status: "present",
    captured_at: now - 5.days,
    metadata: {
      document_id: document_id,
      global_evidence_type: global_evidence_type,
      synthetic_demo: true,
      source_owner: "Northstar Methane Systems"
    }
  )
end

developer_account = Agevidence::DeveloperAccount.create!(
  name: "Northstar Methane Systems",
  website: "https://synthetic.example/northstar",
  funding_stage: "Series A",
  capital_raised_cents: 1_800_000_000,
  primary_segment: "Livestock methane-reduction intervention",
  headquarters: "Synthetic demonstration entity",
  status: "synthetic_demo"
)

riverbend_developer_account = Agevidence::DeveloperAccount.create!(
  name: "Riverbend Verification Labs",
  website: "https://synthetic.example/riverbend",
  funding_stage: "Seed",
  capital_raised_cents: 700_000_000,
  primary_segment: "Agricultural verification workflow",
  headquarters: "Synthetic demonstration entity",
  status: "synthetic_demo"
)

country_adapters = Agevidence::CountryAdapterCatalog.sync!
canada_adapter = country_adapters.detect { |adapter| adapter.adapter_id == "athian-country-ca-beef-v1" }
australia_adapter = country_adapters.detect { |adapter| adapter.adapter_id == "athian-country-au-livestock-v1" }
canada_program = canada_adapter.country_program

developer_project = developer_account.developer_projects.create!(
  protocol: feed_protocol,
  avsa: canonical_avsa,
  country_program: canada_program,
  primary_country_program: canada_program,
  name: "Enterprise Dairy Methane Pilot",
  project_type: "intervention",
  commercialization_stage: "Enterprise dairy pilot",
  target_claim: "The intervention reduces enteric methane for enterprise dairy operations.",
  protocol_status: "review_required",
  integration_status: "source_registered",
  country_context: {
    species: "species.beef_cattle",
    production_system: "production.confined_feeding",
    intervention_class: "intervention.ration_reformulation"
  }
)

[
  ["trial-report-001", "evidence.animal_cohort", "Northstar trial report", "evidence://trial-report-001"],
  ["invoice-001", "evidence.intervention_delivery", "Northstar product invoice", "evidence://invoice-001"],
  ["ration-log-001", "evidence.feed_record", "Northstar ration log", "evidence://ration-log-001"],
  ["measurement-export-001", "evidence.weight_record", "Northstar measurement export", "evidence://measurement-export-001"]
].each do |document_id, evidence_type, title, controlled_uri|
  developer_project.source_records.create!(
    document_id: document_id,
    evidence_type: evidence_type,
    evidence_class: "source_record",
    source_system: "northstar_methane_systems",
    controlled_uri: controlled_uri,
    commitment: commitment.call("developer-os:#{document_id}"),
    disclosure_status: "restricted",
    status: "referenced",
    captured_at: now - 5.days,
    metadata_json: {
      title: title,
      synthetic_demo: true,
      authority_boundary: "Source document remains under Northstar control."
    }
  )
end

model_adapter = Agevidence::ModelAdapter.create!(
  adapter_id: "qwen3.5-4b-reference",
  base_model_id: "Qwen/Qwen3.5-4B",
  provider: "Reference adapter registry entry",
  license: "Reference declaration only; no sponsorship or endorsement implied",
  runtime: "fixture",
  weights_digest: "sha256:qwen35-reference-weights",
  adapter_digest: "sha256:athian-qwen35-reference-adapter",
  context_limit: 32768,
  multimodal: false,
  status: "reference"
)

model_run = Agevidence::ModelRunIngestion.new(
  project: developer_project,
  model_adapter: model_adapter
).call

agevidence_issuer = Agevidence::ReceiptIssuer.new
agevidence_issuer.issue_model_execution!(model_run)
model_run.evidence_candidates.order(:id).each { |candidate| agevidence_issuer.issue_evidence_candidate!(candidate) }

review_plan = [
  ["accepted", "Synthetic reviewer accepted source-linked delivery evidence."],
  ["accepted", "Synthetic reviewer accepted enterprise pilot-period linkage."],
  ["accepted", "Synthetic reviewer accepted measurement export availability."],
  ["accepted", "Synthetic reviewer accepted ration-log source linkage."],
  ["rejected", "Synthetic reviewer rejected dosage consumption as unsupported by the submitted records."],
  ["needs_more_evidence", "Synthetic reviewer requested methodology-version reconciliation."],
  ["needs_more_evidence", "Synthetic reviewer requested independent causal support."]
]

model_run.evidence_candidates.order(:id).zip(review_plan).each do |candidate, (decision, reason)|
  review = candidate.review_decisions.create!(
    reviewer_role: "Synthetic Athian scientific reviewer",
    decision: decision,
    reason: reason,
    policy_version: "ATH-AGEV-POLICY-v1",
    decided_at: now + candidate.id.minutes
  )
  agevidence_issuer.issue_review_decision!(review)
end

source_receipt.evidence_items.create!(
  name: "Northstar Dosage Telemetry Export",
  evidence_type: "dosage_telemetry",
  source_system: "northstar_methane_systems",
  commitment: commitment.call("northstar:dosage-telemetry-001"),
  disclosure_status: "restricted",
  required: true,
  status: "present",
  captured_at: now - 1.day,
  metadata: {
    document_id: "dosage-telemetry-001",
    global_evidence_type: "evidence.baseline_ration",
    synthetic_demo: true,
    source_owner: "Northstar Methane Systems"
  }
)

model_run.evidence_gaps.find_by(gap_type: "missing_independent_support")&.update!(resolution_status: "resolved")

Agevidence::CountryDeterminationAppender.new(project: developer_project, country_adapter: australia_adapter).call if australia_adapter
Agevidence::CountryDeterminationAppender.new(project: developer_project, country_adapter: canada_adapter).call

sprint_product = Agevidence::ProductCatalog.fetch("evidence_architecture_sprint")
sprint_engagement = developer_project.artifact_engagements.create!(
  product_code: "evidence_architecture_sprint",
  pipeline_stage: "scoped",
  billing_type: sprint_product.fetch("billing_type"),
  list_price_cents: sprint_product.fetch("base_planning_price_cents"),
  quoted_price_cents: sprint_product.fetch("base_planning_price_cents"),
  currency: "USD",
  commercial_status: "completed",
  started_on: Date.new(2026, 8, 4),
  completed_on: Date.new(2026, 8, 8)
)
Agevidence::ArtifactAssembler.new(engagement: sprint_engagement).call

readiness_product = Agevidence::ProductCatalog.fetch("verification_readiness_cycle")
readiness_engagement = developer_project.artifact_engagements.create!(
  product_code: "verification_readiness_cycle",
  pipeline_stage: "scoped",
  billing_type: readiness_product.fetch("billing_type"),
  list_price_cents: readiness_product.fetch("base_planning_price_cents"),
  quoted_price_cents: readiness_product.fetch("base_planning_price_cents"),
  currency: "USD",
  commercial_status: "proposed",
  started_on: Date.new(2026, 8, 9)
)
Agevidence::ArtifactAssembler.new(engagement: readiness_engagement).call

reliance_event = readiness_engagement.reliance_events.create!(
  evidence_bundle: readiness_engagement.evidence_bundle,
  relying_party_name: "Synthetic VVB Reliance Review",
  relying_party_role: "vvb",
  decision_type: "verification_readiness_review",
  outcome: "relied_on",
  evidence_bundle_digest: readiness_engagement.evidence_bundle.evidence_bundle_digest,
  occurred_at: now + 2.days,
  notes: "Synthetic VVB reviewer relied on the fixture artifact for demonstration only."
)
agevidence_issuer.issue_reliance_event!(reliance_event)

managed_product = Agevidence::ProductCatalog.fetch("managed_evidence_plane")
developer_project.artifact_engagements.create!(
  product_code: "managed_evidence_plane",
  pipeline_stage: "converted",
  billing_type: managed_product.fetch("billing_type"),
  list_price_cents: managed_product.fetch("base_planning_price_cents"),
  quoted_price_cents: managed_product.fetch("base_planning_price_cents"),
  currency: "USD",
  commercial_status: "active",
  started_on: Date.new(2026, 8, 15)
)

developer_os_quote = Agevidence::PricingEngine.new(
  project: developer_project,
  product_code: "verification_readiness_cycle",
  scope: {
    protocol_complexity: "high",
    evidence_classes: 7,
    source_systems: 4,
    countries: 1,
    relying_parties: 2,
    selective_disclosure: true,
    turnaround_days: 15
  }
).quote
developer_project.artifact_orders.create!(
  pricing_quote: developer_os_quote,
  product_code: developer_os_quote.product_code,
  status: "quoted",
  amount_cents: developer_os_quote.amount_cents,
  currency: developer_os_quote.currency,
  metadata_json: {
    source: "seeded_developer_os",
    sandbox: true,
    note: "Synthetic quote-to-order scaffold. No payment collected."
  }
)
developer_project.update!(integration_status: "relied_on", protocol_status: "aligned")

campaign_country_programs = [
  ["AU", "Oceania", "campaign_ready", "athian-country-au-livestock-v1"],
  ["CA", "North America", "adapter_scaffold", "athian-country-ca-beef-v1"],
  ["NZ", "Oceania", "source_inventory", "athian-country-nz-livestock-research-v1"],
  ["UK", "Europe", "source_inventory", "athian-country-uk-agriculture-research-v1"],
  ["EU", "Europe", "research_not_started", "athian-country-eu-agriculture-research-v1"]
].map do |country_code, region_code, status, adapter_identifier|
  program = Campaign::CountryProgram.create!(
    country_code: country_code,
    region_code: region_code,
    status: status,
    research_status: status,
    adapter_status: status,
    publication_status: status == "campaign_ready" ? "campaign_ready" : "schema_draft",
    developer_guide_status: status == "campaign_ready" ? "campaign_ready" : "fixture_draft",
    commercial_readiness: status == "campaign_ready" ? "campaign_ready" : "external_review",
    canonical_adapter_identifier: adapter_identifier,
    limitations_json: {
      scaffold_status: status,
      unsupported_local_rules: status == "campaign_ready" ? [] : ["Local production rules require external review."],
      architecture_evaluation_only: status != "production_ready"
    }
  )
  program.institution_profiles.create!(
    external_id: "inst_#{country_code.downcase}_buyer_review",
    name: "#{country_code} Buyer Evidence Review",
    institution_type: "buyer",
    status: status,
    requirements_json: { relying_party_type: "buyer" },
    limitations_json: { external_review_required: status != "production_ready" }
  )
  program.obligation_profiles.create!(
    external_id: "obl_#{country_code.downcase}_scope3_buyer_review",
    obligation_code: "scope3_buyer_review",
    name: "#{country_code} Scope 3 buyer review",
    status: status,
    required_evidence_json: { evidence_classes: ["evidence.intervention_delivery", "evidence.feed_record"] },
    limitations_json: { research_only: status != "production_ready" }
  )
  program.adapter_readiness_assessments.create!(
    external_id: "ready_#{country_code.downcase}_#{adapter_identifier.parameterize(separator: '_')}",
    adapter_identifier: adapter_identifier,
    status: status,
    research_only: status != "production_ready",
    external_review_required: status != "production_ready",
    unsupported_rules_json: { unsupported_local_rules: status == "campaign_ready" ? [] : ["External rule interpretation pending."] },
    limitations_json: { artifact_use: status == "production_ready" ? "production" : "architecture_evaluation" },
    assessed_at: now
  )
  program
end

campaign_accounts = [
  {
    external_id: "camp_northstar_au",
    name: "Northstar Methane Systems AU",
    domain: "northstar-methane.example",
    subsector: "Livestock methane-reduction intervention",
    funding_stage: "Series A",
    capital_raised_cents: 1_800_000_000,
    priority_score: 95,
    developer_account: developer_account,
    apollo_account_id: "apollo_acct_northstar_au",
    evidence_obligation_summary: "Buyer-facing Scope 3 review needs controlled source records and evidence gap mapping."
  },
  {
    external_id: "camp_riverbend_au",
    name: "Riverbend Verification Labs AU",
    domain: "riverbend-verification.example",
    subsector: "Verification workflow",
    funding_stage: "Seed",
    capital_raised_cents: 700_000_000,
    priority_score: 84,
    developer_account: riverbend_developer_account,
    apollo_account_id: "apollo_acct_riverbend_au",
    evidence_obligation_summary: "VVB architecture review requires named evidence outcomes and local adapter disclosure."
  },
  { external_id: "camp_southern_pastures_au", name: "Southern Pastures Analytics", domain: "southernpastures.example", subsector: "Grazing analytics", priority_score: 76 },
  { external_id: "camp_coastal_feed_au", name: "Coastal Feed Systems", domain: "coastalfeed.example", subsector: "Feed additive supplier", priority_score: 73 },
  { external_id: "camp_mallee_measurement_au", name: "Mallee Measurement Co", domain: "malleemeasurement.example", subsector: "Measurement product", priority_score: 70 },
  { external_id: "camp_wimmera_data_au", name: "Wimmera Data Exchange", domain: "wimmeradata.example", subsector: "Data platform", priority_score: 67 },
  { external_id: "camp_barossa_supply_au", name: "Barossa Supply Evidence", domain: "barossasupply.example", subsector: "Supply-chain evidence", priority_score: 64 },
  { external_id: "camp_pilbara_carbon_au", name: "Pilbara Carbon Instruments", domain: "pilbaracarbon.example", subsector: "Measurement hardware", priority_score: 61 },
  { external_id: "camp_tasman_trace_au", name: "Tasman Traceability", domain: "tasmantrace.example", subsector: "Traceability platform", priority_score: 58 },
  { external_id: "camp_murray_verification_au", name: "Murray Verification Tools", domain: "murrayverification.example", subsector: "Verification software", priority_score: 55 }
].map do |attrs|
  account = Campaign::Account.create!(
    {
      country_code: "AU",
      status: attrs[:developer_account] ? "developer_activated" : "researched",
      qualification_level: attrs[:developer_account] ? "developer_activated" : "market_qualified",
      authoritative_system: "campaign_fixture",
      evidence_obligation_code: "scope3_buyer_review",
      metadata_json: { synthetic_fixture: true, seeded_at: now.iso8601 }
    }.merge(attrs)
  )
  account.contact_refs.create!(
    display_name: "Technical Sponsor",
    role_category: "technical",
    email_domain: account.domain,
    apollo_person_id: "apollo_person_#{account.external_id}",
    technical_authority: true,
    contactability_status: "contactable",
    last_enriched_at: now,
    metadata_json: { synthetic_fixture: true }
  )
  account
end

northstar_campaign = campaign_accounts.first
northstar_campaign.activation_paths.create!(
  external_id: "act_northstar_project_4030",
  path_type: "cli_project_4030",
  status: "completed",
  repository_sha: "f4ec679c2dd6a2c40e3dced61c81e8f59f90a397",
  cli_version: "0.1.0",
  developer_project_external_id: developer_project.id.to_s,
  invited_at: now - 2.days,
  started_at: now - 1.day,
  completed_at: now,
  support_minutes: 35,
  metadata_json: { fixture: "project_4030" }
)
northstar_campaign.touches.create!(
  touch_type: "cli_replay_completed",
  source_system: "agevidence_cli",
  external_reference: "act_northstar_project_4030",
  repository_sha: "f4ec679c2dd6a2c40e3dced61c81e8f59f90a397",
  content_reference: "examples/integrations/project_4030_beef",
  occurred_at: now,
  metadata_json: { fixture: "project_4030" }
)

canonical_avsa.verification_runs.create!(
  receipt: receipts.first,
  status: "valid",
  verifier_mode: "ink_receipts",
  message: "INK trust-boundary checks passed for the practice receipt.",
  checks: [
    { name: "receipt.structure", status: "valid", detail: "Receipt projection present" },
    { name: "receipt.schema", status: "valid", detail: "Schema commitment present" },
    { name: "receipt.evidence", status: "valid", detail: "Required evidence present" }
  ],
  started_at: now - 3.hours,
  completed_at: now - 3.hours + 1.second
)

secondary_avsa = Avsa.create!(
  protocol: review_protocol,
  external_id: "AVSA-DEMO-2026-0002",
  title: "Upper Midwest Enteric Methane Pilot",
  producer_name: "Prairie Star Dairy",
  intervention_provider: "Methane Systems Lab",
  vvb_name: "Independent Carbon Assurance LLC",
  buyer_name: "Regional Food Group",
  status: "verification_pending",
  verified_quantity: 0,
  unit: "tCO2e",
  started_on: Date.new(2026, 6, 1),
  reporting_period: "2026-Q3",
  root_digest: commitment.call("secondary-avsa-root"),
  local_verification_status: "invalid",
  methodology_name: "VM0042",
  methodology_version: "v0.9"
)

secondary_receipt = create_receipt.call(
  avsa: secondary_avsa,
  type: "practice_receipt",
  title: "Practice Receipt under annual-review hold",
  lifecycle: "observed",
  domain: "review_required",
  issuer: "Athian Governance",
  sequence: 1,
  parents: [],
  schema: "athian.practice_receipt.v1",
  status: "invalid",
  evidence: [
    { name: "Annual Review Decision", type: "registry_record", source: "governance_repository", disclosure: "public", status: "missing" }
  ]
)

secondary_avsa.verification_exceptions.create!(
  receipt: secondary_receipt,
  code: "PROTOCOL.ANNUAL_REVIEW.STALE",
  severity: "critical",
  status: "open",
  materiality: "New enrollment blocked",
  description: "The protocol is under annual review and cannot support new enrollment until a current decision is sealed.",
  owner: "Governance Committee",
  due_on: Date.new(2026, 8, 6)
)

secondary_avsa.verification_runs.create!(
  receipt: secondary_receipt,
  status: "invalid",
  verifier_mode: "ink_receipts",
  message: "Annual review evidence is missing.",
  checks: [
    { name: "receipt.evidence", status: "invalid", detail: "Annual review decision missing" },
    { name: "protocol.status", status: "invalid", detail: "Protocol is under annual review" }
  ],
  started_at: now - 2.hours,
  completed_at: now - 2.hours + 1.second
)

puts "Seeded #{Protocol.count} protocols, #{Avsa.count} AVSAs, #{Receipt.count} receipts, #{EvidenceItem.count} evidence items, #{EvidenceBundle.count} bundle projections, #{Agevidence::SourceRecord.count} source records, #{Agevidence::PricingQuote.count} quote(s), #{Agevidence::ArtifactOrder.count} artifact order(s), #{MethodologyMigration.count} migration(s), #{Agevidence::DeveloperProject.count} AgEvidence project(s), and #{Campaign::Account.count} campaign account(s)."

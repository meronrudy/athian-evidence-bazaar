module EvidenceInstrumentHelper
  EI_STATUS_TONES = {
    "valid" => "valid",
    "verified" => "valid",
    "accepted" => "valid",
    "eligible" => "valid",
    "fulfilled" => "issued",
    "issued" => "issued",
    "sealed" => "sealed",
    "attested" => "sealed",
    "human_review" => "human_review",
    "review_required" => "human_review",
    "eligible_with_conditions" => "human_review",
    "needs_more_evidence" => "human_review",
    "indeterminate" => "human_review",
    "invalid" => "material_gap",
    "failed" => "material_gap",
    "insufficient_evidence" => "material_gap",
    "outside_current_method" => "material_gap",
    "draft" => "draft",
    "queued" => "draft",
    "generated" => "draft",
    "unverified" => "unverified",
    "superseded" => "superseded"
  }.freeze

  def ei_status_tone(value)
    EI_STATUS_TONES.fetch(value.to_s.downcase, "unverified")
  end

  def ei_status(label, status: nil)
    render "shared/evidence_instrument/status", label: label, tone: ei_status_tone(status || label)
  end

  def ei_basis_link(url, label: "View basis")
    link_to label, url, class: "ei-basis-link"
  end

  def ei_project_provenance_nodes(project)
    run = project.model_runs.order(created_at: :desc).first
    determination = project.country_determinations.order(evaluated_at: :desc).first
    order = project.artifact_orders.includes(:evidence_bundle).order(created_at: :desc).detect(&:evidence_bundle)
    adapter = determination&.country_adapter || project.primary_country_program&.country_adapters&.first

    [
      {
        label: "Source",
        identifier: "#{project.source_records.count} source records",
        detail: project.developer_account.name,
        status: "valid",
        url: agevidence_developer_project_source_records_path(project)
      },
      {
        label: "Evidence",
        identifier: "#{project.source_documents.size} committed items",
        detail: compact_digest(project.evidence_graph_root),
        status: project.source_documents.any? ? "valid" : "draft",
        url: agevidence_developer_project_path(project)
      },
      {
        label: "Profile",
        identifier: adapter&.adapter_id || project.primary_country_program&.country_code || "Unassigned",
        detail: adapter&.version || project.primary_country_program&.name,
        status: adapter&.status || "draft",
        url: adapter ? agevidence_country_program_path(adapter.country_program) : agevidence_country_programs_path
      },
      {
        label: "Evaluation",
        identifier: run ? "RUN-#{run.id}" : "Pending",
        detail: run&.status&.humanize || "No model run",
        status: run&.status || "draft",
        url: run ? agevidence_model_run_path(run) : new_agevidence_developer_project_model_run_path(project)
      },
      {
        label: "Determination",
        identifier: determination ? "DET-#{determination.id}" : "Pending",
        detail: determination&.status&.humanize || "No country determination",
        status: determination&.status || "draft",
        url: determination ? agevidence_determination_path(determination) : agevidence_determinations_path
      },
      {
        label: "Artifact",
        identifier: order&.evidence_bundle ? "artifact_#{order.evidence_bundle.id}" : "Pending",
        detail: order&.status&.humanize || "No reliance artifact",
        status: order&.status || "draft",
        url: order ? agevidence_developer_project_artifact_order_path(project, order) : new_agevidence_developer_project_pricing_quote_path(project)
      }
    ]
  end

  def ei_avsa_provenance_nodes(avsa)
    first_receipt = avsa.receipts.order(:sequence).first
    latest_receipt = avsa.receipts.order(:sequence).last
    bundle = avsa.evidence_bundles.order(generated_at: :desc).first
    run = avsa.verification_runs.recent_first.first
    evidence_url = first_receipt || latest_receipt

    [
      { label: "Source", identifier: avsa.producer_name, detail: avsa.external_id, status: "valid", url: avsa_path(avsa) },
      { label: "Evidence", identifier: "#{avsa.receipts.count} receipts", detail: compact_digest(avsa.root_digest), status: avsa.local_verification_status, url: evidence_url ? receipt_path(evidence_url) : avsa_path(avsa) },
      { label: "Profile", identifier: avsa.methodology_label, detail: avsa.protocol.display_name, status: "sealed", url: protocol_path(avsa.protocol) },
      { label: "Evaluation", identifier: run ? "RUN-#{run.id}" : "Local verifier", detail: run&.status || avsa.local_verification_status, status: run&.status || avsa.local_verification_status, url: verifier_console_path(avsa_id: avsa.id) },
      { label: "Determination", identifier: latest_receipt&.receipt_type_label || "Pending", detail: latest_receipt&.title, status: latest_receipt&.lifecycle_state || "draft", url: latest_receipt ? receipt_path(latest_receipt) : avsa_path(avsa) },
      { label: "Artifact", identifier: bundle&.artifact_filename || "Bundle pending", detail: bundle&.verification_status || "No export", status: bundle&.verification_status || "draft", url: bundle_exports_path(avsa_id: avsa.id) }
    ]
  end

  def ei_country_profile_stack_layers(country_program, adapters)
    adapter = adapters.first || country_program.country_adapters.first
    method_version = adapter&.country_method_version
    claim_policy = adapter&.country_claim_policy
    verification_profile = adapter&.country_verification_profile
    data_policy = adapter&.country_data_policy

    [
      { "label" => "Methodology", "identifier" => method_version&.method_id || country_program.name, "version" => method_version&.version || "pending", "description" => method_version&.country_method&.authority_name },
      { "label" => "Requirements", "identifier" => "#{country_program.country_code.downcase}.required_evidence", "version" => adapter&.version || "pending", "description" => "#{adapter&.required_evidence&.size || 0} evidence obligations" },
      { "label" => "Claim policy", "identifier" => claim_policy&.policy_id || "claim_policy.pending", "version" => claim_policy&.version || "pending", "description" => "Bounds buyer and verifier reliance claims." },
      { "label" => "Verification", "identifier" => verification_profile&.profile_id || "verification.pending", "version" => verification_profile&.version || "pending", "description" => "Defines receipt and signature checks." },
      { "label" => "Data policy", "identifier" => data_policy&.policy_id || "data_policy.pending", "version" => data_policy&.version || "pending", "description" => "Defines disclosure and source handling." },
      { "label" => "Artifact", "identifier" => "ink_receipts.bundle", "version" => adapter&.version || "pending", "description" => "Produces portable receipts and bundles." }
    ]
  end

  def ei_receipt_checks(receipt)
    [
      ["Canonical digest", receipt.body_digest.present? ? "MATCH" : "MISSING", receipt.body_digest.present?],
      ["Issuer signature", receipt.signer_key_id.present? ? "VALID" : "MISSING", receipt.signer_key_id.present?],
      ["Evidence commitment", receipt.evidence_commitment.present? ? "MATCH" : "MISSING", receipt.evidence_commitment.present?],
      ["Policy commitment", receipt.policy_commitment.present? ? "MATCH" : "MISSING", receipt.policy_commitment.present?],
      ["Lifecycle", receipt.lifecycle_state.upcase, receipt.verified?]
    ]
  end
end

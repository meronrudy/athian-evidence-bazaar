module Agevidence
  class CountryDeterminationAppender
    def initialize(project:, country_adapter:, institution_profile: nil)
      @project = project
      @country_adapter = country_adapter
      @institution_profile = institution_profile
    end

    def call
      prior = latest_prior_determination
      result = CountryEligibilityEvaluator.new(
        project: project,
        country_adapter: country_adapter,
        institution_profile: institution_profile,
        supersedes: prior&.result_digest || prior&.receipt&.body_digest
      ).call
      ensure_adapter_commitment!
      receipt = issue_determination_receipt(result)

      project.country_determinations.create!(
        country_program: country_adapter.country_program,
        country_adapter: country_adapter,
        country_method_version: country_adapter.country_method_version,
        supersedes: prior,
        receipt: receipt,
        status: result.fetch("status"),
        normalized_result: result,
        result_digest: receipt.body_digest,
        evaluated_at: Time.zone.parse(result.fetch("evaluated_at"))
      )
    end

    private

    attr_reader :project, :country_adapter, :institution_profile

    def ensure_adapter_commitment!
      return if country_adapter.commitment_receipt
      return unless project.avsa

      issued = InkReceipts.issue_country_adapter_commitment(
        payload: adapter_commitment_payload,
        issuer: "Athian Country Adapter Registry",
        signer: "did:key:athian-country-adapter-demo"
      )
      receipt = create_receipt!(
        issued: issued,
        title: "Country Adapter Commitment Receipt",
        domain_state: "country_adapter_version_committed",
        parents: []
      )
      country_adapter.update!(commitment_receipt: receipt)
    end

    def issue_determination_receipt(result)
      issued = InkReceipts.issue_country_determination(
        payload: result.merge(
          "evidence_graph_root" => project.evidence_graph_root,
          "adapter_commitment_receipt" => country_adapter.commitment_receipt&.body_digest
        ),
        parents: [project.evidence_graph_root, country_adapter.commitment_receipt&.body_digest].compact,
        issuer: "Athian Country Compatibility Demo",
        signer: "did:key:athian-country-determination-demo"
      )
      create_receipt!(
        issued: issued,
        title: "Country Compatibility Determination Receipt",
        domain_state: "country_policy_interpreted_evidence_graph",
        parents: [evidence_chain_anchor, country_adapter.commitment_receipt].compact.uniq
      )
    end

    def create_receipt!(issued:, title:, domain_state:, parents:)
      raise "Project must be linked to an AVSA to persist country receipts." unless project.avsa

      project.avsa.receipts.create!(
        receipt_type: issued.fetch(:receipt_type),
        title: title,
        lifecycle_state: issued.fetch(:lifecycle_state),
        domain_state: domain_state,
        issuer_name: issued.fetch(:issuer),
        signer_key_id: issued.fetch(:signer_key_id),
        schema_id: issued.fetch(:schema_id),
        schema_digest: issued.fetch(:schema_digest),
        body_digest: issued.fetch(:body_digest),
        evidence_commitment: issued.fetch(:evidence_commitment),
        policy_commitment: issued.fetch(:policy_commitment),
        trace_commitment: issued.fetch(:trace_commitment),
        sequence: project.avsa.receipts.maximum(:sequence).to_i + 1,
        parent_receipt_ids: parents.map(&:id),
        canonical_encoding_hex: issued.fetch(:canonical_encoding_hex),
        integrity_status: issued.fetch(:integrity_status),
        signed_at: Time.current,
        sealed_at: Time.current
      )
    end

    def adapter_commitment_payload
      manifest = country_adapter.manifest
      method = manifest.fetch("method")
      {
        adapter_id: country_adapter.adapter_id,
        adapter_version: country_adapter.version,
        country_code: country_adapter.country_code,
        method_id: method.fetch("id"),
        method_version: method.fetch("version"),
        eligibility_rules_digest: "sha256:#{country_adapter.adapter_id}:eligibility:#{country_adapter.version}",
        claim_policy_digest: "sha256:#{country_adapter.country_claim_policy&.policy_id}:#{country_adapter.version}",
        verification_profile_digest: "sha256:#{country_adapter.country_verification_profile&.profile_id}:#{country_adapter.version}",
        data_policy_digest: "sha256:#{country_adapter.country_data_policy&.policy_id}:#{country_adapter.version}",
        artifact_profile_digests: Array(manifest.fetch("artifact_profiles")).map { |profile| "sha256:#{profile}:#{country_adapter.version}" },
        authority_declaration: "Athian compatibility implementation",
        limitations: country_adapter.limitations
      }
    end

    def latest_prior_determination
      project.country_determinations.where(country_adapter: country_adapter).order(evaluated_at: :desc).first
    end

    def evidence_chain_anchor
      project.avsa&.receipts&.where.not(
        receipt_type: %w[
          country_adapter_commitment_receipt
          country_compatibility_determination_receipt
        ]
      )&.order(:sequence)&.last
    end
  end
end

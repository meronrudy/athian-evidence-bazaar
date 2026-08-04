module InkReceipts
  class << self
    def build_reliance_artifact(product_code:, project:, receipts:, output_dir:, scope: {}, profile: nil, evidence_graph_root: nil, determination_receipt: nil, relying_party: nil)
      Client.new.build_reliance_artifact(
        product_code: product_code,
        project: project,
        receipts: receipts,
        output_dir: output_dir,
        scope: scope,
        profile: profile,
        evidence_graph_root: evidence_graph_root,
        determination_receipt: determination_receipt,
        relying_party: relying_party
      )
    end

    def issue_reliance_event(payload:, parents: [], issuer:, signer:)
      Client.new.issue_agevidence(
        payload: payload,
        receipt_type: "reliance_event_receipt",
        schema: "athian.agevidence.reliance_event.v1",
        parents: parents,
        issuer: issuer,
        signer: signer
      )
    end
  end

  class Client
    def build_reliance_artifact(product_code:, project:, receipts:, output_dir:, scope: {}, profile: nil, evidence_graph_root: nil, determination_receipt: nil, relying_party: nil)
      generated_at = Time.now.utc.iso8601
      profile ||= {}
      determination_digest = determination_receipt && determination_receipt.fetch(:body_digest)
      root_reference = evidence_graph_root || project.fetch(:avsa).fetch(:root_digest, project.fetch(:avsa).fetch(:external_id))
      artifact_digest = issue(
        payload: {
          product_code: product_code,
          project: project,
          profile: profile,
          evidence_graph_root: root_reference,
          determination_receipt: determination_digest,
          relying_party: relying_party,
          included_receipts: receipts.map { |receipt| receipt.fetch(:body_digest) },
          scope: scope,
          generated_at: generated_at
        },
        issuer: "Athian AgEvidence Artifact Assembly",
        receipt_type: "artifact_assembly_receipt",
        schema: "athian.agevidence.artifact_assembly.v1",
        parents: receipts.map { |receipt| receipt.fetch(:body_digest) },
        lifecycle: "sealed",
        avsa: project.fetch(:avsa).fetch(:external_id),
        signer: "did:key:athian-artifact-demo"
      ).fetch(:body_digest)

      manifest = {
        manifest_version: "athian.agevidence.artifact.manifest.v1",
        generated_at: generated_at,
        bundle_type: product_code,
        bundle_name: scope.fetch(:product_name, product_code.to_s.tr("_", " ").split.map(&:capitalize).join(" ")),
        audience: profile.dig("profile", "audience") || "Protocol, VVB, buyer, auditor, sponsor, or insurer",
        problem: "Portable AgEvidence artifact for external reliance.",
        avsa: project.fetch(:avsa),
        project: project.except(:avsa),
        evidence_graph_root: root_reference,
        determination_receipt: determination_digest,
        relying_party: relying_party,
        artifact_profile: profile,
        required_receipts: Array(profile["required_receipts"]),
        required_documents: Array(profile["required_documents"]),
        artifact_digest: artifact_digest,
        receipts: receipts,
        claim_group: nil,
        producer_payment: nil,
        verification_command: "ink verify-bundle manifest.json --policy trust/trust-policy.json",
        trust_policy: DEFAULT_POLICY,
        limitations: [
          "This artifact is a portable evidence acceptance packet.",
          "Rails does not perform cryptography or verification.",
          scope.fetch(:notice, Catalog::PRODUCT_NOTICE)
        ]
      }

      bundle(bundle_type: "auditor", output_dir: output_dir, manifest: manifest)
    end
  end
end

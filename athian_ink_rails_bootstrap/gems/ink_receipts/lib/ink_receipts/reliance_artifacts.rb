module InkReceipts
  class << self
    def build_reliance_artifact(product_code:, project:, receipts:, output_dir:, scope: {})
      Client.new.build_reliance_artifact(
        product_code: product_code,
        project: project,
        receipts: receipts,
        output_dir: output_dir,
        scope: scope
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
    def build_reliance_artifact(product_code:, project:, receipts:, output_dir:, scope: {})
      generated_at = Time.now.utc.iso8601
      artifact_digest = issue(
        payload: {
          product_code: product_code,
          project: project,
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
        audience: "Protocol, VVB, buyer, auditor, sponsor, or insurer",
        problem: "Portable AgEvidence artifact for external reliance.",
        avsa: project.fetch(:avsa),
        project: project.except(:avsa),
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

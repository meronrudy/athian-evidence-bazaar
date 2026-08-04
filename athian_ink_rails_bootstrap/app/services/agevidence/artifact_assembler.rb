module Agevidence
  class ArtifactAssembler
    def initialize(engagement:)
      @engagement = engagement
      @project = engagement.developer_project
    end

    def call
      raise "Project must be linked to an AVSA before artifact assembly" unless project.avsa

      product = ProductCatalog.fetch(engagement.product_code)
      result = InkReceipts.build_reliance_artifact(
        product_code: engagement.product_code,
        project: project_projection,
        receipts: project.avsa.receipts.order(:sequence).map { |receipt| InkProjection.receipt(receipt) },
        output_dir: Rails.root.join("tmp/exports").to_s,
        scope: { product_name: product.fetch("name"), notice: ProductCatalog.notice }
      )

      bundle = project.avsa.evidence_bundles.create!(
        bundle_type: "auditor",
        name: product.fetch("name"),
        audience: "Protocol, VVB, buyer, auditor, sponsor, or insurer",
        problem: product.fetch("description"),
        status: "generated",
        artifact_filename: result.fetch(:filename),
        artifact_path: result.fetch(:path),
        verification_status: result.fetch(:verification_report).fetch(:status),
        manifest: result.fetch(:manifest),
        generated_at: Time.current,
        commercial_product_code: engagement.product_code,
        artifact_version: "v1",
        reliance_status: "not_relied_on",
        list_price_cents: engagement.list_price_cents,
        quoted_price_cents: engagement.quoted_price_cents,
        acceptance_receipt: project.avsa.receipts.order(:sequence).last
      )

      engagement.update!(evidence_bundle: bundle, pipeline_stage: "assembled")
      bundle
    end

    private

    attr_reader :engagement, :project

    def project_projection
      {
        id: project.id,
        name: project.name,
        target_claim: project.target_claim,
        avsa: InkProjection.avsa(project.avsa)
      }
    end
  end
end

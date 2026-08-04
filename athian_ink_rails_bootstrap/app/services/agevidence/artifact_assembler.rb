module Agevidence
  class ArtifactAssembler
    def initialize(engagement:)
      @engagement = engagement
      @project = engagement.developer_project
    end

    def call
      raise "Project must be linked to an AVSA before artifact assembly" unless project.avsa

      product = ProductCatalog.fetch(engagement.product_code)
      determination = project.country_program ? project.refresh_country_determination! : project.country_determination
      result = InkReceipts.build_reliance_artifact(
        product_code: engagement.product_code,
        project: project_projection(determination),
        receipts: project.avsa.receipts.order(:sequence).map { |receipt| InkProjection.receipt(receipt) },
        output_dir: Rails.root.join("tmp/exports").to_s,
        scope: {
          product_name: product.fetch("name"),
          notice: ProductCatalog.notice,
          country_determination: determination
        }
      )

      bundle = project.avsa.evidence_bundles.create!(
        bundle_type: "auditor",
        name: product.fetch("name"),
        audience: "Protocol, VVB, buyer, auditor, sponsor, insurer, government, or standards body",
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
        acceptance_receipt: project.avsa.receipts.order(:sequence).last,
        country_claim_policy: project.country_program&.country_claim_policies&.order(created_at: :desc)&.first,
        country_verification_profile: project.country_program&.country_verification_profiles&.order(created_at: :desc)&.first
      )

      engagement.update!(evidence_bundle: bundle, pipeline_stage: "assembled")
      bundle
    end

    private

    attr_reader :engagement, :project

    def project_projection(determination)
      {
        id: project.id,
        name: project.name,
        target_claim: project.target_claim,
        country_program: project.country_program&.code,
        country_context: project.country_context,
        country_determination: determination,
        avsa: InkProjection.avsa(project.avsa)
      }
    end
  end
end

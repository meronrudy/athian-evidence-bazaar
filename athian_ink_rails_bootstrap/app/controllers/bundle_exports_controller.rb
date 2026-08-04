class BundleExportsController < ApplicationController
  def index
    @avsas = Avsa.includes(:protocol).order(:external_id)
    @bundle_types = BundleManifestBuilder::BUNDLE_TYPES
    @recent_bundles = EvidenceBundle.includes(:avsa).order(generated_at: :desc).limit(8)
  end

  def create
    avsa = Avsa.includes(receipts: :evidence_items).find(params[:avsa_id])
    bundle_type = params.require(:bundle_type)
    manifest = BundleManifestBuilder.new(avsa: avsa, bundle_type: bundle_type).call
    result = BundleZipBuilder.new(manifest: manifest, avsa: avsa, bundle_type: bundle_type).call
    path = result.fetch(:path)
    avsa.evidence_bundles.create!(
      bundle_type: bundle_type,
      name: manifest.fetch(:bundle_name),
      audience: manifest.fetch(:audience),
      problem: manifest.fetch(:problem),
      status: "downloaded",
      artifact_filename: result.fetch(:filename),
      artifact_path: path,
      verification_status: result.fetch(:verification_report).fetch(:status),
      manifest: manifest,
      generated_at: Time.current
    )

    send_file path,
              filename: File.basename(path),
              type: "application/zip",
              disposition: "attachment"
  rescue KeyError, ArgumentError, InkReceipts::Error => e
    redirect_to bundle_exports_path, alert: e.message
  end
end

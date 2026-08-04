class BundleZipBuilder
  def initialize(manifest:, avsa:, bundle_type:)
    @manifest = manifest
    @avsa = avsa
    @bundle_type = bundle_type
  end

  def call
    InkReceipts.bundle(
      manifest: manifest,
      bundle_type: bundle_type,
      output_dir: Rails.root.join("tmp", "exports").to_s
    )
  end

  private

  attr_reader :manifest, :avsa, :bundle_type
end

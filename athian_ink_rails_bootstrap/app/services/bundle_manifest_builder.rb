class BundleManifestBuilder
  BUNDLE_TYPES = InkReceipts::BUNDLE_TYPES

  def initialize(avsa:, bundle_type:)
    @avsa = avsa
    @bundle_type = bundle_type
  end

  def call
    InkReceipts.bundle_manifest(
      avsa: InkProjection.avsa(avsa),
      bundle_type: bundle_type,
      receipts: avsa.receipts.includes(:evidence_items).order(:sequence).map { |receipt| InkProjection.receipt(receipt) },
      claim_group: InkProjection.claim_group(avsa.claim_group),
      producer_payment: InkProjection.producer_payment(avsa.producer_payment)
    )
  rescue InkReceipts::Error => e
    raise ArgumentError, e.message
  end

  private

  attr_reader :avsa, :bundle_type
end

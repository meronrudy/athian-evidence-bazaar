class EvidenceMarketplaceController < ApplicationController
  def index
    @products = InkReceipts::MARKET_PRODUCTS
    @bundle_types = InkReceipts::BUNDLE_TYPES
  end

  def show
    @product_key = params[:id]
    @product = InkReceipts::MARKET_PRODUCTS.fetch(@product_key)
    @bundle_type = InkReceipts::BUNDLE_TYPES.fetch(@product.fetch(:bundle_type))
    @avsa = canonical_avsa
  rescue KeyError
    redirect_to evidence_marketplace_index_path, alert: "Unknown evidence product."
  end
end

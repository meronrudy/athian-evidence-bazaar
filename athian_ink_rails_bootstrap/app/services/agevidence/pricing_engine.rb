module Agevidence
  class PricingEngine
    def initialize(project:, product_code:, scope: {})
      @project = project
      @product_code = product_code.to_s
      @scope = scope.to_h.deep_stringify_keys
    end

    def quote
      product = ProductCatalog.fetch(product_code)
      breakdown = [{ component: "base_price", amount_cents: product.fetch("base_planning_price_cents") }]
      breakdown << component("protocol_complexity", 0.2) if scope["protocol_complexity"] == "high"
      breakdown << component("evidence_classes", 0.05 * [scope["evidence_classes"].to_i - 3, 0].max)
      breakdown << component("source_systems", 0.04 * [scope["source_systems"].to_i - 2, 0].max)
      breakdown << component("relying_parties", 0.05 * [scope["relying_parties"].to_i - 1, 0].max)
      breakdown << component("country_policy_count", 0.08 * [scope["countries"].to_i - 1, 0].max)
      breakdown << component("selective_disclosure", 0.15) if ActiveModel::Type::Boolean.new.cast(scope["selective_disclosure"])
      breakdown << component("fast_turnaround", 0.15) if scope["turnaround_days"].to_i.positive? && scope["turnaround_days"].to_i < 21

      amount = breakdown.sum { |item| item.fetch(:amount_cents) }
      project.pricing_quotes.create!(
        product_code: product_code,
        pricing_version: PricingQuote::PRICING_VERSION,
        currency: "USD",
        amount_cents: amount,
        input_json: scope.merge("product_code" => product_code),
        breakdown_json: breakdown,
        status: "quoted",
        expires_at: 30.days.from_now
      )
    end

    private

    attr_reader :project, :product_code, :scope

    def component(name, multiplier)
      base = ProductCatalog.fetch(product_code).fetch("base_planning_price_cents")
      { component: name, amount_cents: (base * multiplier).round }
    end
  end
end

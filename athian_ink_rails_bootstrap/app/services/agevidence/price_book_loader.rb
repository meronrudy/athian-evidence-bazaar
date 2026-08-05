module Agevidence
  class PriceBookLoader
    CONFIG_PATH = Rails.root.join("config/agevidence/artifact_pricing.yml").freeze

    def self.call
      new.call
    end

    def call
      config = YAML.safe_load_file(CONFIG_PATH, aliases: false)
      version = config.fetch("version")
      currency = config.fetch("currency")

      config.fetch("products").each do |product_code, attributes|
        price_book = PriceBook.find_or_initialize_by(product_code: product_code, version: version)
        price_book.assign_attributes(
          name: attributes.fetch("name"),
          currency: currency,
          billing_model: attributes.fetch("billing_model"),
          base_amount_cents: attributes.fetch("base_amount_cents"),
          minimum_amount_cents: attributes.fetch("minimum_amount_cents"),
          unit_name: attributes["unit_name"],
          included_units: attributes.fetch("included_units", 0),
          overage_amount_cents: attributes.fetch("overage_amount_cents", 0),
          dimensions: attributes.fetch("dimensions", {}),
          active: true,
          effective_at: Time.zone.parse(version)
        )
        price_book.save!
      end
    end
  end
end

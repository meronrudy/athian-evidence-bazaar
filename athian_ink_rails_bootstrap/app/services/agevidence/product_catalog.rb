require "yaml"

module Agevidence
  class ProductCatalog
    class << self
      def all
        config.fetch("products")
      end

      def notice
        config.fetch("notice")
      end

      def pricing_factors
        config.fetch("pricing_factors")
      end

      def fetch(code)
        all.fetch(code.to_s)
      end

      private

      def config
        @config ||= YAML.load_file(Rails.root.join("config/agevidence/products.yml"))
      end
    end
  end
end

require "yaml"

module Agevidence
  class CountryAdapterCatalog
    ROOT = Rails.root.dirname.join("specs/agevidence/country_adapters").freeze

    class << self
      def all
        Dir[ROOT.join("*.yml")].sort.map { |path| load_file(path) }
      end

      def fetch(code)
        all.find { |entry| entry.dig("country", "code") == code.to_s.upcase } ||
          raise(KeyError, "unknown country adapter: #{code}")
      end

      private

      def load_file(path)
        YAML.safe_load(File.read(path), aliases: false).tap do |entry|
          raise "country adapter missing country code: #{path}" if entry.dig("country", "code").blank?
          raise "country adapter missing adapter id: #{path}" if entry.dig("adapter", "adapter_id").blank?
        end
      end
    end
  end
end

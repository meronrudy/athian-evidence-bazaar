require "yaml"

module Agevidence
  class RevenueProjection
    YEARS = %w[y1 y2 y3].freeze

    def self.from_config(path = Rails.root.join("config/agevidence/revenue_scenarios.yml"))
      new(config: YAML.load_file(path))
    end

    def initialize(config:)
      @config = config
    end

    def streams
      config.fetch("streams").map do |code, stream|
        totals = YEARS.to_h do |year|
          [year, stream.fetch("price_cents").to_i * stream.fetch("units").fetch(year).to_i]
        end
        stream.merge("code" => code, "totals" => totals)
      end
    end

    def base_totals
      YEARS.to_h do |year|
        [year, streams.sum { |stream| stream.fetch("totals").fetch(year) }]
      end
    end

    def recurring_totals
      YEARS.to_h do |year|
        [year, streams.select { |stream| stream.fetch("recurring") }.sum { |stream| stream.fetch("totals").fetch(year) }]
      end
    end

    def episodic_totals
      YEARS.to_h do |year|
        [year, base_totals.fetch(year) - recurring_totals.fetch(year)]
      end
    end

    def scenario_summaries
      config.fetch("scenario_summaries")
    end

    private

    attr_reader :config
  end
end

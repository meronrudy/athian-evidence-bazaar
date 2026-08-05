module Agevidence
  class ArtifactPricing
    COUNT_DIMENSIONS = {
      "evidence_classes" => "evidence_class_cents",
      "source_systems" => "source_system_cents",
      "review_hours" => "review_hour_cents",
      "relying_parties" => "relying_party_cents",
      "selective_disclosure_profiles" => "selective_disclosure_profile_cents",
      "country_adapters" => "country_adapter_cents",
      "migration_events" => "migration_event_cents",
      "portfolio_companies" => "portfolio_company_cents",
      "affected_assets" => "affected_asset_cents"
    }.freeze

    Result = Data.define(:price_book, :amount_cents, :currency, :breakdown)

    def initialize(price_book:, input:)
      @price_book = price_book
      @input = input.to_h.stringify_keys
    end

    def call
      line_items = [{ code: "base", quantity: 1, unit_amount_cents: price_book.base_amount_cents, amount_cents: price_book.base_amount_cents }]

      COUNT_DIMENSIONS.each do |input_key, rate_key|
        quantity = nonnegative_number(input.fetch(input_key, 0))
        unit_amount = integer_dimension(rate_key)
        next if quantity.zero? || unit_amount.zero?

        line_items << {
          code: input_key,
          quantity: quantity,
          unit_amount_cents: unit_amount,
          amount_cents: (quantity * unit_amount).round
        }
      end

      subtotal = line_items.sum { |item| item.fetch(:amount_cents) }
      rush = ActiveModel::Type::Boolean.new.cast(input["rush"])
      rush_percentage = rush ? integer_dimension("rush_percentage") : 0
      rush_amount = (subtotal * rush_percentage / 100.0).round
      line_items << { code: "rush", quantity: rush_percentage, unit_amount_cents: 0, amount_cents: rush_amount } if rush_amount.positive?

      calculated = subtotal + rush_amount
      total = [calculated, price_book.minimum_amount_cents].max
      line_items << {
        code: "minimum_adjustment",
        quantity: 1,
        unit_amount_cents: total - calculated,
        amount_cents: total - calculated
      } if total > calculated

      Result.new(
        price_book: price_book,
        amount_cents: total,
        currency: price_book.currency,
        breakdown: {
          product_code: price_book.product_code,
          price_book_version: price_book.version,
          billing_model: price_book.billing_model,
          line_items: line_items,
          subtotal_cents: subtotal,
          rush_amount_cents: rush_amount,
          total_cents: total
        }
      )
    end

    private

    attr_reader :price_book, :input

    def integer_dimension(key)
      price_book.dimensions.to_h.fetch(key, 0).to_i
    end

    def nonnegative_number(value)
      number = BigDecimal(value.to_s)
      raise ArgumentError, "pricing dimensions must be nonnegative" if number.negative?

      number
    rescue ArgumentError
      raise ArgumentError, "invalid pricing dimension: #{value.inspect}"
    end
  end
end

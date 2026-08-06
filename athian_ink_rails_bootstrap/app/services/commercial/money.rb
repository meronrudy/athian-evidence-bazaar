module Commercial
  module Money
    CURRENCIES = {
      "USD" => { precision: 2, symbol: "$" },
      "AUD" => { precision: 2, symbol: "$" },
      "NZD" => { precision: 2, symbol: "$" },
      "CAD" => { precision: 2, symbol: "$" },
      "EUR" => { precision: 2, symbol: "€" },
      "GBP" => { precision: 2, symbol: "£" },
      "JPY" => { precision: 0, symbol: "¥" },
      "BRL" => { precision: 2, symbol: "R$" }
    }.freeze

    def self.format(amount_cents, currency = "USD")
      return "0.00" if amount_cents.nil?

      precision = CURRENCIES[currency.to_s.upcase]&.fetch(:precision, 2) || 2
      symbol = CURRENCIES[currency.to_s.upcase]&.fetch(:symbol, "$") || "$"

      amount = amount_cents.to_f / (10 ** precision)
      formatted = amount.to_s.split('.').first + '.' + amount.to_s.split('.').last.ljust(precision, '0')[0...precision]
      "#{symbol}#{formatted}"
    end

    def self.validate_currency(currency)
      CURRENCIES.key?(currency.to_s.upcase)
    end
  end
end

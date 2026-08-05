module Campaign
  module MetadataBoundary
    FORBIDDEN_KEY_PATTERN = /
      secret|token|password|api[_-]?key|refresh[_-]?token|
      raw[_-]?email|email[_-]?body|source[_-]?document|
      banking|bank[_-]?account|presigned|unredacted
    /ix

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def validates_campaign_metadata(*attributes)
        attributes.each do |attribute|
          validate do
            Campaign::MetadataBoundary.validate!(record: self, attribute: attribute)
          end
        end
      end
    end

    def self.validate!(record:, attribute:)
      value = record.public_send(attribute)
      return if value.blank?

      unless value.is_a?(Hash)
        record.errors.add(attribute, "must be a JSON object")
        return
      end

      forbidden_paths(value).each do |path|
        record.errors.add(attribute, "contains forbidden private or secret field #{path}")
      end
    end

    def self.forbidden_paths(value, prefix = nil)
      case value
      when Hash
        value.flat_map do |key, item|
          path = [prefix, key].compact.join(".")
          key.to_s.match?(FORBIDDEN_KEY_PATTERN) ? [path] : forbidden_paths(item, path)
        end
      when Array
        value.each_with_index.flat_map { |item, index| forbidden_paths(item, "#{prefix}[#{index}]") }
      else
        []
      end
    end
  end
end

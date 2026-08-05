module Agevidence
  class CountryMethodVersion < ApplicationRecord
    STATUSES = %w[active pilot scaffold research superseded retired].freeze

    belongs_to :country_method, class_name: "Agevidence::CountryMethod"
    has_many :country_adapters, class_name: "Agevidence::CountryAdapter", dependent: :restrict_with_error

    validates :version, :status, presence: true
    validates :version, uniqueness: { scope: :country_method_id }
    validates :status, inclusion: { in: STATUSES }

    def method_id
      country_method.method_id
    end
  end
end

module Agevidence
  class DeveloperAccount < ApplicationRecord
    STATUSES = %w[active paused archived synthetic_demo].freeze

    has_many :developer_projects, class_name: "Agevidence::DeveloperProject", dependent: :destroy

    validates :name, presence: true, uniqueness: true
    validates :status, inclusion: { in: STATUSES }
    validates :capital_raised_cents, numericality: { greater_than_or_equal_to: 0 }
  end
end

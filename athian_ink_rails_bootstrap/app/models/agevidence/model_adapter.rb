module Agevidence
  class ModelAdapter < ApplicationRecord
    STATUSES = %w[reference available disabled superseded].freeze

    has_many :model_runs, class_name: "Agevidence::ModelRun", dependent: :restrict_with_error

    validates :adapter_id, :base_model_id, :status, presence: true
    validates :adapter_id, uniqueness: true
    validates :status, inclusion: { in: STATUSES }

    def display_name
      "#{adapter_id} (#{base_model_id})"
    end
  end
end

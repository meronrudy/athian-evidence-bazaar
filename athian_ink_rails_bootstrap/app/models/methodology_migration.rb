class MethodologyMigration < ApplicationRecord
  STATUSES = %w[pending impact_review appended verified superseded].freeze

  belongs_to :avsa
  belongs_to :delta_receipt, class_name: "Receipt", optional: true

  validates :old_methodology, :old_version, :new_methodology, :new_version, :status, presence: true
  validates :status, inclusion: { in: STATUSES }

  def transition_label
    "#{old_methodology} #{old_version} -> #{new_methodology} #{new_version}"
  end
end

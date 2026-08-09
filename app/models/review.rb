class Review < ApplicationRecord
  belongs_to :project
  belongs_to :reviewer, class_name: 'User', optional: true

  validates :title, presence: true
  validates :description, presence: true
  validates :status, inclusion: { in: %w[open in_progress resolved] }

  scope :ordered, -> { order(created_at: :desc) }
end
class Event < ApplicationRecord
  validates :title, presence: true
  validates :description, presence: true
  validates :occurred_at, presence: true
end
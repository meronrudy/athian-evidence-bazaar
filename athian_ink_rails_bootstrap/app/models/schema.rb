class Schema < ApplicationRecord
  belongs_to :project, optional: true

  scope :recent, -> { order(updated_at: :desc) }
  scope :by_type, ->(type) { where(type: type) }

  validates :name, presence: true
  validates :version, presence: true
  validates :definition, presence: true

  def definition_hash
    JSON.parse(definition)
  rescue JSON::ParserError
    {}
  end

  def definition_pretty
    JSON.pretty_generate(definition_hash)
  end
end
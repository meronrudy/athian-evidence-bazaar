class RequiredEvidence < ApplicationRecord
  belongs_to :country_program
  belongs_to :requirement_profile, optional: true

  validates :evidence_type, presence: true
  validates :obligation, presence: true
  validates :applies_when, presence: true, allow_nil: true
  validates :cardinality, presence: true, allow_nil: true
  validates :accepted_sources, presence: true, allow_nil: true
  validates :integrity, presence: true, allow_nil: true
  validates :review, presence: true, allow_nil: true
  validates :authority_refs, presence: true, allow_nil: true

  scope :satisfied, -> { where(status: 'satisfied') }
  scope :missing, -> { where(status: 'missing') }
  scope :not_applicable, -> { where(status: 'not_applicable') }
  scope :conflict, -> { where(status: 'conflict') }
  scope :requires_review, -> { where(status: 'requires_review') }

  def status
    return self[:status] if self[:status]
    # Default logic to determine status based on evidence availability
    if evidence_available?
      'satisfied'
    else
      'missing'
    end
  end

  def evidence_available?
    # This would check against the actual evidence graph
    # For now, return true for demonstration
    true
  end

  def to_yaml
    {
      'id' => id,
      'evidence_type' => evidence_type,
      'obligation' => obligation,
      'applies_when' => applies_when,
      'cardinality' => cardinality,
      'accepted_sources' => accepted_sources,
      'integrity' => integrity,
      'review' => review,
      'authority_refs' => authority_refs
    }.to_yaml
  end

  def self.from_yaml(yaml_data)
    data = YAML.safe_load(yaml_data, aliases: true)
    create(
      evidence_type: data['evidence_type'],
      obligation: data['obligation'],
      applies_when: data['applies_when'],
      cardinality: data['cardinality'],
      accepted_sources: data['accepted_sources'],
      integrity: data['integrity'],
      review: data['review'],
      authority_refs: data['authority_refs']
    )
  end
end
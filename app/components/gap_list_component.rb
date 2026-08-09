class GapListComponent < ApplicationComponent
  def initialize(gaps:)
    @gaps = gaps
  end

  def call
    # Render gap list with severity-based styling
    @gaps.each do |gap|
      div class: 'gap-card', data: { severity: gap.severity } do
        h3 gap.title
        p gap.description
        span class: 'severity-badge', style: { background_color: gap.severity_color } do
          gap.severity.upcase
        end
      end
    end
  end
end
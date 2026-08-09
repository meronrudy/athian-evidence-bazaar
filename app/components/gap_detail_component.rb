class GapDetailComponent < ApplicationComponent
  def initialize(gap:)
    @gap = gap
  end

  def call
    div class: 'gap-detail' do
      div class: 'gap-header' do
        h2 @gap.title
        span class: "severity-badge severity-#{@gap.severity}" do
          @gap.severity.upcase
        end
      end

      div class: 'gap-meta' do
        dl do
          dt 'Status'
          dd @gap.status.humanize
          dt 'Source Record'
          dd @gap.source_record&.identifier
          dt 'Event'
          dd @gap.event&.name
          dt 'Candidate'
          dd @gap.candidate&.name
          dt 'Created'
          dd @gap.created_at.strftime('%B %d, %Y')
          dt 'Updated'
          dd @gap.updated_at.strftime('%B %d, %Y')
        end
      end

      div class: 'gap-description' do
        h3 'Description'
        p @gap.description
      end

      if @gap.resolution.present?
        div class: 'gap-resolution' do
          h3 'Resolution'
          p @gap.resolution
        end
      end

      div class: 'gap-actions' do
        button class: 'btn btn-primary', data: { action: 'click->gap-detail#resolve' } do
          'Mark Resolved'
        end
        button class: 'btn btn-secondary', data: { action: 'click->gap-detail#dismiss' } do
          'Dismiss'
        end
      end
    end
  end
end
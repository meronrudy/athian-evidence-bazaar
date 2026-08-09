class CandidateInspectorComponent < ApplicationComponent
  def initialize(candidate:)
    @candidate = candidate
  end

  def call
    div class: 'candidate-inspector' do
      h3 'Evidence Candidate'
      dl do
        dt 'ID'
        dd @candidate.id
        dt 'Name'
        dd @candidate.name
        dt 'Status'
        dd @candidate.status.humanize
        dt 'Confidence'
        dd "#{(@candidate.confidence * 100).round(1)}%"
        dt 'Created'
        dd @candidate.created_at.strftime('%B %d, %Y')
      end

      if @candidate.evidence_items.any?
        div class: 'candidate-evidence' do
          h4 'Supporting Evidence'
          ul do
            @candidate.evidence_items.each do |item|
              li do
                span class: 'evidence-type' do
                  item.evidence_type.humanize
                end
                span class: 'evidence-status' do
                  item.status.humanize
                end
              end
            end
          end
        end
      end

      div class: 'candidate-actions' do
        button class: 'btn btn-primary', data: { action: 'click->candidate-inspector#accept' } do
          'Accept'
        end
        button class: 'btn btn-secondary', data: { action: 'click->candidate-inspector#reject' } do
          'Reject'
        end
        button class: 'btn btn-outline', data: { action: 'click->candidate-inspector#request-more' } do
          'Request More Info'
        end
      end
    end
  end
end
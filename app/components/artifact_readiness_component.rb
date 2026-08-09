class ArtifactReadinessComponent < ApplicationComponent
  def initialize(artifact:)
    @artifact = artifact
  end

  def call
    div class: 'artifact-readiness' do
      h3 'Artifact Readiness'
      
      div class: 'readiness-indicator' do
        div class: "readiness-dot status-#{readiness_status}" do
          span class: 'sr-only' do
            readiness_status.humanize
          end
        end
        span class: 'readiness-label' do
          readiness_status.humanize
        end
      end

      if @artifact.issues.any?
        div class: 'artifact-issues' do
          h4 'Issues'
          ul class: 'issues-list' do
            @artifact.issues.each do |issue|
              li class: "issue-item severity-#{issue.severity}" do
                div class: 'issue-header' do
                  strong issue.title
                  span class: "issue-severity severity-#{issue.severity}" do
                    issue.severity.upcase
                  end
                end
                p issue.description
                div class: 'issue-meta' do
                  span class: 'issue-assignee' do
                    "Assigned to: #{issue.assignee || 'Unassigned'}"
                  end
                  span class: 'issue-due-date' do
                    "Due: #{issue.due_date.strftime('%m/%d/%Y')}"
                  end
                end
              end
            end
          end
        end
      end

      div class: 'artifact-actions' do
        button class: 'btn btn-primary', data: { action: 'click->artifact-readiness#markReady' } do
          'Mark as Ready'
        end
        button class: 'btn btn-outline', data: { action: 'click->artifact-readiness#requestReview' } do
          'Request Review'
        end
      end
    end
  end

  private

  def readiness_status
    if @artifact.ready?
      :ready
    elsif @artifact.issues.any? { |issue| issue.severity == 'high' }
      :blocked
    elsif @artifact.issues.any?
      :in_progress
    else
      :not_started
    end
  end
end
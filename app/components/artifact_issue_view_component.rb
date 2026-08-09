class ArtifactIssueViewComponent < ApplicationComponent
  def initialize(artifact:)
    @artifact = artifact
  end

  def call
    div class: 'artifact-issues-view' do
      h3 'Artifact Issues'
      
      if @artifact.issues.empty?
        p 'No issues found for this artifact.'
      else
        ul class: 'issues-list' do
          @artifact.issues.each do |issue|
            li class: "issue-item severity-#{issue.severity}" do
              div class: 'issue-card' do
                h4 issue.title
                p issue.description
                div class: 'issue-meta' do
                  span class: 'issue-severity' do
                    issue.severity.upcase
                  end
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

      div class: 'issue-actions' do
        button class: 'btn btn-sm btn-primary', data: { action: 'click->artifact-issue-view#resolve' } do
          'Resolve Issue'
        end
        button class: 'btn btn-sm btn-outline', data: { action: 'click->artifact-issue-view#viewDetails' } do
          'View Details'
        end
      end
    end
  end
end
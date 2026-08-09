class ReviewEntryComponent < ApplicationComponent
  def initialize(review:)
    @review = review
  end

  def call
    div class: 'review-entry', data: { review_id: @review.id } do
      div class: 'review-header' do
        div class: 'review-meta' do
          span class: "review-status status-#{@review.status}" do
            @review.status.humanize
          end
          span class: 'review-date' do
            @review.created_at.strftime('%b %d, %Y')
          end
          if @review.reviewer.present?
            span class: 'reviewer-avatar' do
              image_tag @review.reviewer.avatar_url, alt: "#{@review.reviewer.name}'s avatar", class: 'avatar-sm'
            end
          end
        end
        h4 @review.title
      end

      div class: 'review-body' do
        p @review.description
        if @review.artifacts.any?
          div class: 'review-artifacts' do
            h5 'Artifacts'
            ul do
              @review.artifacts.each do |artifact|
                li do
                  strong artifact.name
                  span class: "artifact-status status-#{artifact.status}" do
                    artifact.status.humanize
                  end
                end
              end
            end
          end
        end
      end

      div class: 'review-footer' do
        div class: 'review-actions' do
          case @review.status
          when 'open'
            button class: 'btn btn-sm btn-primary', data: { action: 'click->review-entry#startReview' } do
              'Start Review'
            end
          when 'in_progress'
            button class: 'btn btn-sm btn-success', data: { action: 'click->review-entry#completeReview' } do
              'Complete'
            end
            button class: 'btn btn-sm btn-outline', data: { action: 'click->review-entry#requestChanges' } do
              'Request Changes'
            end
          when 'resolved'
            span class: 'btn btn-sm btn-success' do
              'Resolved'
            end
          end
          button class: 'btn btn-sm btn-outline', data: { action: 'click->review-entry#viewDetails' } do
            'Details'
          end
        end
      end
    end
  end
end
class ReviewQueueComponent < ApplicationComponent
  def initialize(pending_reviews:)
    @pending_reviews = pending_reviews
  end

  def call
    return if @pending_reviews.empty?

    div class: 'review-queue' do
      h3 'Reviewer Queue'
      ul class: 'queue-list' do
        @pending_reviews.each do |review|
          li class: 'queue-item' do
            div class: 'queue-item-header' do
              strong review.title
              span class: 'badge bg-warning', style: { margin_left: '0.5rem' } do
                'Pending'
              end
            end
            p review.description.truncate(100)
            div class: 'queue-item-actions' do
              button class: 'btn btn-sm btn-primary', data: { action: 'click->review-queue#assign' } do
                'Assign'
              end
              button class: 'btn btn-sm btn-info', data: { action: 'click->review-queue#view' } do
                'View'
              end
            end
          end
        end
      end
    end
  end
end
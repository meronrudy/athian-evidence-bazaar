class ReviewLedgerComponent < ApplicationComponent
  def initialize(project:)
    @project = project
    @reviews = project.reviews.ordered
  end

  def call
    div class: 'review-ledger' do
      div class: 'ledger-header' do
        h3 'Review Ledger'
        div class: 'ledger-actions' do
          button class: 'btn btn-primary', data: { action: 'click->review-ledger#newReview' } do
            'New Review'
          end
        end
      end

      div class: 'ledger-timeline' do
        @reviews.each do |review|
          render ReviewEntryComponent.new(review: review)
        end
      end

      if @reviews.empty?
        div class: 'ledger-empty' do
          p 'No reviews yet. Start a new review to begin the ledger.'
        end
      end
    end
  end
end
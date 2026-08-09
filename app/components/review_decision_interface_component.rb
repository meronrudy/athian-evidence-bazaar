class ReviewDecisionInterfaceComponent < ApplicationComponent
  def initialize(review:)
    @review = review
  end

  def call
    div class: 'review-decision-interface' do
      h3 'Review Decision'
      
      div class: 'decision-form' do
        div class: 'form-group' do
          label 'Decision', for: 'decision'
          select class: 'form-control', id: 'decision', name: 'decision' do
            option 'Select decision...', value: ''
            option 'Approved', value: 'approved'
            option 'Rejected', value: 'rejected'
            option 'Requires Changes', value: 'requires_changes'
          end
        end

        div class: 'form-group' do
          label 'Comments', for: 'comments'
          textarea class: 'form-control', id: 'comments', name: 'comments', rows: 4
        end

        div class: 'form-group' do
          label 'Attachments', for: 'attachments'
          input type: 'file', class: 'form-control', id: 'attachments', name: 'attachments', multiple: true
        end

        div class: 'form-actions' do
          button class: 'btn btn-primary', type: 'submit' do
            'Submit Decision'
          end
          button class: 'btn btn-outline', type: 'button', data: { action: 'click->review-decision-interface#cancel' } do
            'Cancel'
          end
        end
      end
    end
  end
end
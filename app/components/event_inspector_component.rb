class EventInspectorComponent < ApplicationComponent
  def initialize(event:)
    @event = event
  end

  def call
    div class: 'event-inspector' do
      h3 'Event Details'
      dl do
        dt 'ID'
        dd @event.id
        dt 'Name'
        dd @event.name
        dt 'Type'
        dd @event.event_type.humanize
        dt 'Timestamp'
        dd @event.timestamp.strftime('%B %d, %Y %I:%M %p')
        dt 'Source'
        dd @event.source
      end

      if @event.payload.present?
        div class: 'event-payload' do
          h4 'Payload'
          pre class: 'payload-json' do
            code do
              plain_text JSON.pretty_generate(@event.payload)
            end
          end
        end
      end

      div class: 'event-actions' do
        button class: 'btn btn-primary', data: { action: 'click->event-inspector#replay' } do
          'Replay Event'
        end
        button class: 'btn btn-secondary', data: { action: 'click->event-inspector#view-details' } do
          'View Full Details'
        end
      end
    end
  end
end
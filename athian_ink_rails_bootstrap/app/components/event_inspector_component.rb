class EventInspectorComponent < ViewComponent::Base
  def initialize(events:)
    @events = events
  end

  def render
    html = ""
    html << "<h3>Event Inspector</h3>"
    html << "<div class=\"event-list\">"
    @events.each do |event|
      html << "<div class=\"event-item\">"
      html << "<h4>#{event.title}</h4>"
      html << "<p>#{event.description}</p>"
      html << "<p><strong>Occurred:</strong> #{event.occurred_at}</p>"
      html << "</div>"
    end
    html << "</div>"
    html
  end
end
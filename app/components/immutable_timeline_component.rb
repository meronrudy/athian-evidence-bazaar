class ImmutableTimelineComponent < ApplicationComponent
  def initialize(project:)
    @project = project
    @timeline = build_timeline
  end

  def call
    div class: 'immutable-timeline' do
      h3 'Immutable Timeline'
      
      if @timeline.empty?
        p 'No timeline entries yet. Start a review to create entries.'
      else
        div class: 'timeline-container' do
          @timeline.each do |entry|
            render TimelineEntryComponent.new(entry: entry)
          end
        end
      end
    end
  end

  private

  def build_timeline
    # Build timeline entries from project reviews and decisions
    []
  end
end
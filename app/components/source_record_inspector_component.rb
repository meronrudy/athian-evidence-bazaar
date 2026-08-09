class SourceRecordInspectorComponent < ApplicationComponent
  def initialize(source_record:)
    @source_record = source_record
  end

  def call
    div class: 'source-record-inspector' do
      h3 'Source Record Details'
      dl do
        dt 'ID'
        dd @source_record.id
        dt 'Type'
        dd @source_record.type.humanize
        dt 'Created'
        dd @source_record.created_at.strftime('%B %d, %Y')
        dt 'Last Modified'
        dd @source_record.updated_at.strftime('%B %d, %Y')
      end

      div class: 'source-actions' do
        button class: 'btn btn-primary', data: { action: 'click->source-record-inspector#view' } do
          'View Full Record'
        end
      end
    end
  end
end
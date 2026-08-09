class EvidenceInboxComponent < ViewComponent::Base
  def initialize(evidence_events:)
    @evidence_events = evidence_events
  end

  def call
    content_tag :div, class: "evidence-inbox" do
      concat header
      concat table
      concat filters
    end
  end

  private

  def header
    content_tag :div, class: "inbox-header" do
      h2 "Evidence Inbox"
      span "#{@evidence_events.count} events"
    end
  end

  def table
    content_tag :table, class: "table table-hover" do
      concat thead
      concat tbody
    end
  end

  def thead
    content_tag :thead do
      tr do
        th "Status"
        th "Evidence"
        th "Source"
        th "Received"
        th "Project"
        th "Result"
      end
    end
  end

  def tbody
    content_tag :tbody do
      @evidence_events.each do |event|
        concat tr(event)
      end
    end
  end

  def tr(event)
    content_tag :tr, class: row_class(event) do
      td event.status_badge
      td event.name
      td event.source
      td event.received_at
      td event.project
      td event.result_badge
    end
  end

  def row_class(event)
    case event.status
    when "accepted"
      "table-success"
    when "needs_attention"
      "table-warning"
    when "rejected"
      "table-danger"
    else
      ""
    end
  end

  def filters
    content_tag :div, class: "filters mt-3" do
      content_tag :div, class: "btn-group" do
        button "All", class: "btn btn-outline-primary active"
        button "Needs attention", class: "btn btn-outline-warning"
        button "Accepted", class: "btn btn-outline-success"
        button "Rejected", class: "btn btn-outline-danger"
      end
    end
  end
end
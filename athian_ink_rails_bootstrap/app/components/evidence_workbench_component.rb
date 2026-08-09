class EvidenceWorkbenchComponent < ViewComponent::Base
  def initialize(project)
    @project = project
  end

  def call
    content_tag :div, class: "evidence-workbench" do
      concat header
      concat content_tag(:div, class: "workbench-grid") do
        concat evidence_sources_panel
        concat evidence_graph_panel
        concat reliance_status_panel
      end
    end
  end

  private

  def header
    content_tag :div, class: "workbench-header" do
      concat content_tag(:h1, @project.name)
      concat content_tag(:div, "Evidence → Assessment → Review → Reliance", class: "workbench-flow")
    end
  end

  def evidence_sources_panel
    content_tag :div, class: "panel evidence-sources" do
      h3 "EVIDENCE SOURCES"
      ul do
        @project.evidence_sources.each do |source|
          li do
            span source.status_badge
            span source.name
            span source.received_at
            span source.project
            span source.result
          end
        end
      end
      concat link_to "+ Add evidence", new_project_evidence_path(@project), class: "btn btn-primary"
    end
  end

  def evidence_graph_panel
    content_tag :div, class: "panel evidence-graph" do
      h3 "EVIDENCE GRAPH"
      # This would render a visual graph of evidence lineage
      div class: "graph-placeholder" do
        "Evidence lineage graph"
      end
    end
  end

  def reliance_status_panel
    content_tag :div, class: "panel reliance-status" do
      h3 "RELIANCE STATUS"
      div class: "metrics" do
        span "18 accepted"
        span "3 gaps"
        span "2 review items"
        span "Ready: 82%"
      end
      concat link_to "Review gaps", project_gaps_path(@project), class: "btn btn-outline-primary"
      concat link_to "Build artifact", project_artifact_path(@project), class: "btn btn-primary"
    end
  end
end
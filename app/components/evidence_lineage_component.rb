class EvidenceLineageComponent < ApplicationComponent
  def initialize(project:)
    @project = project
    @nodes = build_lineage_nodes
    @edges = build_lineage_edges
  end

  def call
    div class: 'evidence-lineage', data: { controller: 'lineage-graph' } do
      div class: 'lineage-header' do
        h3 'Evidence Lineage'
        div class: 'lineage-controls' do
          button class: 'btn btn-sm btn-outline', data: { action: 'click->lineage-graph#zoomIn' } do
            'Zoom In'
          end
          button class: 'btn btn-sm btn-outline', data: { action: 'click->lineage-graph#zoomOut' } do
            'Zoom Out'
          end
          button class: 'btn btn-sm btn-outline', data: { action: 'click->lineage-graph#resetView' } do
            'Reset'
          end
        end
      end

      div class: 'lineage-graph-container', data: { lineage_graph_target: 'container' } do
        # SVG graph will be rendered here by Stimulus controller
        div class: 'lineage-placeholder' do
          p 'Evidence lineage graph visualization'
          p class: 'text-muted' do
            'Showing source records → events → candidates → evidence items'
          end
        end
      end

      div class: 'lineage-legend' do
        h4 'Legend'
        ul class: 'legend-items' do
          li do
            span class: 'legend-color', style: { background_color: '#3b82f6' }
            span 'Source Record'
          end
          li do
            span class: 'legend-color', style: { background_color: '#8b5cf6' }
            span 'Event'
          end
          li do
            span class: 'legend-color', style: { background_color: '#f59e0b' }
            span 'Candidate'
          end
          li do
            span class: 'legend-color', style: { background_color: '#10b981' }
            span 'Evidence Item'
          end
          li do
            span class: 'legend-color', style: { background_color: '#ef4444' }
            span 'Gap'
          end
        end
      end
    end
  end

  private

  def build_lineage_nodes
    # Build nodes from project's source records, events, candidates, evidence items
    []
  end

  def build_lineage_edges
    # Build edges showing relationships
    []
  end
end
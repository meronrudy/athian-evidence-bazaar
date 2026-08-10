class EvaluationPlaygroundComponent < ViewComponent::Base
  def initialize(country_programs:, evidence_graphs:, institution_overlays: [])
    @country_programs = country_programs
    @evidence_graphs = evidence_graphs
    @institution_overlays = institution_overlays
  end

  def render
    content = '<div class="evaluation-playground">'
    content << '<h2>Evaluation Playground</h2>'
    content << '<p class="description">Run dry-run evaluations against any adapter/profile combination without creating determinations.</p>'
    
    # Form for evaluation
    content << '<form id="evaluation-form" data-controller="evaluation-playground">'
    content << '<div class="form-row">'
    content << '  <div class="form-group">'
    content << '    <label for="evidence-graph">Evidence Graph</label>'
    content << '    <select name="evidence_graph_id" id="evidence-graph" required>'
    content << '      <option value="">Select evidence graph...</option>'
    @evidence_graphs.each do |graph|
      content << "      <option value=\"#{graph.id}\">#{graph.name} (#{graph.id})</option>"
    end
    content << '    </select>'
    content << '  </div>'
    
    content << '  <div class="form-group">'
    content << '    <label for="country">Country</label>'
    content << '    <select name="country_code" id="country" required>'
    content << '      <option value="">Select country...</option>'
    content << '      <option value="AU">Australia</option>'
    content << '      <option value="NZ">New Zealand</option>'
    content << '      <option value="CA">Canada</option>'
    content << '      <option value="EU">European Union</option>'
    content << '      <option value="BR">Brazil</option>'
    content << '      <option value="JP">Japan</option>'
    content << '      <option value="IE">Ireland</option>'
    content << '      <option value="UK">United Kingdom</option>'
    content << '    </select>'
    content << '  </div>'
    content << '</div>'
    
    content << '<div class="form-row">'
    content << '  <div class="form-group">'
    content << '    <label for="program">Program</label>'
    content << '    <select name="program_id" id="program" required disabled>'
    content << '      <option value="">Select country first...</option>'
    content << '    </select>'
    content << '  </div>'
    
    content << '  <div class="form-group">'
    content << '    <label for="adapter">Adapter Version</label>'
    content << '    <select name="adapter_version" id="adapter" required disabled>'
    content << '      <option value="">Select program first...</option>'
    content << '    </select>'
    content << '  </div>'
    content << '</div>'
    
    content << '<div class="form-row">'
    content << '  <div class="form-group">'
    content << '    <label for="institution-overlay">Institution Overlay (Optional)</label>'
    content << '    <select name="institution_overlay_id" id="institution-overlay">'
    content << '      <option value="">None</option>'
    @institution_overlays.each do |overlay|
      content << "      <option value=\"#{overlay.id}\">#{overlay.name} v#{overlay.version}</option>"
    end
    content << '    </select>'
    content << '  </div>'
    content << '</div>'
    
    content << '<div class="form-actions">'
    content << '  <button type="submit" class="btn btn-primary" data-action="evaluation-playground#runEvaluation">Run Evaluation</button>'
    content << '  <button type="button" class="btn btn-secondary" data-action="evaluation-playground#clearResults">Clear Results</button>'
    content << '</div>'
    content << '</form>'
    
    # Results area
    content << '<div id="evaluation-results" class="evaluation-results hidden">'
    content << '  <h3>Evaluation Results</h3>'
    content << '  <div class="result-summary">'
    content << '    <div class="result-status">'
    content << '      <span class="status-badge" id="result-status">Pending</span>'
    content << '    </div>'
    content << '    <div class="result-meta">'
    content << '      <p><strong>Evidence Graph:</strong> <span id="result-evidence-graph">-</span></p>'
    content << '      <p><strong>Adapter:</strong> <span id="result-adapter">-</span></p>'
    content << '      <p><strong>Method:</strong> <span id="result-method">-</span></p>'
    content << '    </div>'
    content << '  </div>'
    
    content << '  <div class="result-tabs">'
    content << '    <ul class="nav nav-tabs">'
    content << '      <li class="nav-item"><a class="nav-link active" href="#summary">Summary</a></li>'
    content << '      <li class="nav-item"><a class="nav-link" href="#requirements">Requirements</a></li>'
    content << '      <li class="nav-item"><a class="nav-link" href="#policy-stack">Policy Stack</a></li>'
    content << '      <li class="nav-item"><a class="nav-link" href="#evidence">Evidence</a></li>'
    content << '      <li class="nav-item"><a class="nav-link" href="#conflicts">Conflicts</a></li>'
    content << '      <li class="nav-item"><a class="nav-link" href="#artifact-preview">Artifact Preview</a></li>'
    content << '      <li class="nav-item"><a class="nav-link" href="#raw-result">Raw Result</a></li>'
    content << '    </ul>'
    content << '  </div>'
    
    content << '  <div class="tab-content">'
    content << '    <div class="tab-pane active" id="summary">'
    content << '      <div id="summary-content">Evaluation summary will appear here...</div>'
    content << '    </div>'
    
    content << '    <div class="tab-pane" id="requirements">'
    content << '      <div id="requirements-content">Requirements breakdown will appear here...</div>'
    content << '    </div>'
    
    content << '    <div class="tab-pane" id="policy-stack">'
    content << '      <div id="policy-stack-content">Policy stack visualization will appear here...</div>'
    content << '    </div>'
    
    content << '    <div class="tab-pane" id="evidence">'
    content << '      <div id="evidence-content">Evidence details will appear here...</div>'
    content << '    </div>'
    
    content << '    <div class="tab-pane" id="conflicts">'
    content << '      <div id="conflicts-content">Conflicts will appear here...</div>'
    content << '    </div>'
    
    content << '    <div class="tab-pane" id="artifact-preview">'
    content << '      <div id="artifact-preview-content">Artifact preview will appear here...</div>'
    content << '    </div>'
    
    content << '    <div class="tab-pane" id="raw-result">'
    content << '      <pre id="raw-result-content">Raw JSON result will appear here...</pre>'
    content << '    </div>'
    content << '  </div>'
    
    content << '  <div class="result-actions">'
    content << '    <button type="button" class="btn btn-success" id="publish-determination" disabled data-action="evaluation-playground#publishDetermination">Publish as Determination</button>'
    content << '    <button type="button" class="btn btn-secondary" data-action="evaluation-playground#downloadResult">Download Result</button>'
    content << '  </div>'
    content << '</div>'
    
    content << '</div>'
    content.html_safe
  end
end
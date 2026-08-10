class CountryProgramDetailComponent < ViewComponent::Base
  def initialize(country_program:)
    @country_program = country_program
  end

  def render
    content = '<div class="country-program-detail">'
    content << '<h2>Program Detail</h2>'
    content << '<div class="program-overview">'
    content << "<h3>#{@country_program.name}</h3>"
    content << "<p><strong>Country:</strong> #{@country_program.country_code}</p>"
    content << "<p><strong>Description:</strong> #{@country_program.description}</p>"
    content << "<p><strong>Status:</strong> <span class=\"status-badge status-#{@country_program.status.downcase}\">#{@country_program.status}</span></p>"
    content << "<p><strong>Active Adapters:</strong> #{@country_program.adapter_count}</p>"
    content << '</div>'

    # Tabs for different sections
    content << '<div class="program-tabs">'
    content << '<ul class="nav nav-tabs">'
    content << '<li class="nav-item"><a class="nav-link active" href="#overview">Overview</a></li>'
    content << '<li class="nav-item"><a class="nav-link" href="#requirements">Requirements</a></li>'
    content << '<li class="nav-item"><a class="nav-link" href="#profiles">Profiles</a></li>'
    content << '<li class="nav-item"><a class="nav-link" href="#versions">Versions</a></li>'
    content << '<li class="nav-item"><a class="nav-link" href="#evaluate">Evaluate</a></li>'
    content << '<li class="nav-item"><a class="nav-link" href="#determinations">Determinations</a></li>'
    content << '<li class="nav-item"><a class="nav-link" href="#artifacts">Artifacts</a></li>'
    content << '<li class="nav-item"><a class="nav-link" href="#sources">Sources</a></li>'
    content << '</ul>'
    content << '</div>'

    # Tab content
    content << '<div class="tab-content">'
    content << '<div class="tab-pane active" id="overview">'
    content << '<h4>Program Overview</h4>'
    content << "<p>#{@country_program.description}</p>"
    content << '<h4>Active Adapters</h4>'
    content << '<ul class="adapter-list">'
    # This would be populated with actual adapter data
    content << '<li>AU v1 - Livestock Pilot</li>'
    content << '<li>NZ v1 - Dairy Pilot</li>'
    content << '</ul>'
    content << '</div>'

    content << '<div class="tab-pane" id="requirements">'
    content << '<h4>Evidence Requirements</h4>'
    content << '<div class="requirements-list">'
    # This would be populated with actual requirement data
    content << '<div class="requirement-item">'
    content << '<span class="requirement-id">AU-INT-001</span>'
    content << '<span class="requirement-name">Intervention Delivery</span>'
    content << '<span class="requirement-status status-satisfied">Satisfied</span>'
    content << '</div>'
    content << '<div class="requirement-item">'
    content << '<span class="requirement-id">AU-FEED-001</span>'
    content << '<span class="requirement-name">Feed Record</span>'
    content << '<span class="requirement-status status-missing">Missing</span>'
    content << '</div>'
    content << '</div>'
    content << '</div>'

    content << '<div class="tab-pane" id="profiles">'
    content << '<h4>Profiles</h4>'
    content << '<div class="profiles-list">'
    # This would be populated with actual profile data
    content << '<div class="profile-item">'
    content << '<span class="profile-name">AU-Livestock-Method v1.0</span>'
    content << '<span class="profile-type">Method</span>'
    content << '</div>'
    content << '<div class="profile-item">'
    content << '<span class="profile-name">AU-Claim-Policy v1.0</span>'
    content << '<span class="profile-type">Claim Policy</span>'
    content << '</div>'
    content << '</div>'
    content << '</div>'

    content << '<div class="tab-pane" id="versions">'
    content << '<h4>Version History</h4>'
    content << '<div class="version-list">'
    # This would be populated with actual version data
    content << '<div class="version-item">'
    content << '<span class="version-number">v1.0</span>'
    content << '<span class="version-date">2024-01-15</span>'
    content << '<span class="version-status">Active</span>'
    content << '</div>'
    content << '<div class="version-item">'
    content << '<span class="version-number">v0.9</span>'
    content << '<span class="version-date">2023-11-20</span>'
    content << '<span class="version-status">Superseded</span>'
    content << '</div>'
    content << '</div>'
    content << '</div>'

    content << '<div class="tab-pane" id="evaluate">'
    content << '<h4>Evaluation Playground</h4>'
    content << '<p><a href="/country_programs/#{@country_program.id}/evaluate" class="btn btn-primary">Run Evaluation</a></p>'
    content << '</div>'

    content << '<div class="tab-pane" id="determinations">'
    content << '<h4>Determinations</h4>'
    content << '<div class="determinations-list">'
    # This would be populated with actual determination data
    content << '<div class="determination-item">'
    content << '<span class="determination-id">DET-001</span>'
    content << '<span class="determination-date">2024-01-20</span>'
    content << '<span class="determination-result">Eligible with conditions</span>'
    content << '</div>'
    content << '</div>'
    content << '</div>'

    content << '<div class="tab-pane" id="artifacts">'
    content << '<h4>Required Artifacts</h4>'
    content << '<div class="artifact-list">'
    # This would be populated with actual artifact data
    content << '<div class="artifact-item">'
    content << '<span class="artifact-name">Country Determination</span>'
    content << '<span class="artifact-status status-required">Required</span>'
    content << '</div>'
    content << '<div class="artifact-item">'
    content << '<span class="artifact-name">Evidence Inventory</span>'
    content << '<span class="artifact-status status-required">Required</span>'
    content << '</div>'
    content << '</div>'
    content << '</div>'

    content << '<div class="tab-pane" id="sources">'
    content << '<h4>Source Information</h4>'
    content << '<div class="source-list">'
    # This would be populated with actual source data
    content << '<div class="source-item">'
    content << '<span class="source-authority">AU Government</span>'
    content << '<span class="source-document">Livestock Guidelines v2.1</span>'
    content << '</div>'
    content << '</div>'
    content << '</div>'

    content << '</div>'
    content << '</div>'
    content << '</div>'
    content.html_safe
  end
end

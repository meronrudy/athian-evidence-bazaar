class CountryProgramBrowserComponent < ViewComponent::Base
  def initialize(country_programs:, filters: {})
    @country_programs = country_programs
    @filters = filters
  end

  def render
    content = '<div class="country-program-browser">'
    content << '<h2>Country Program Engine</h2>'
    
    # Filters
    content << '<div class="filters">'
    content << '<form method="get">'
    content << '  <select name="country">'
    content << '    <option value="">All Countries</option>'
    content << '    <option value="AU"' + (@filters[:country] == 'AU' ? ' selected' : '') + '>Australia</option>'
    content << '    <option value="NZ"' + (@filters[:country] == 'NZ' ? ' selected' : '') + '>New Zealand</option>'
    content << '    <option value="CA"' + (@filters[:country] == 'CA' ? ' selected' : '') + '>Canada</option>'
    content << '    <option value="EU"' + (@filters[:country] == 'EU' ? ' selected' : '') + '>European Union</option>'
    content << '    <option value="BR"' + (@filters[:country] == 'BR' ? ' selected' : '') + '>Brazil</option>'
    content << '    <option value="JP"' + (@filters[:country] == 'JP' ? ' selected' : '') + '>Japan</option>'
    content << '    <option value="IE"' + (@filters[:country] == 'IE' ? ' selected' : '') + '>Ireland</option>'
    content << '    <option value="UK"' + (@filters[:country] == 'UK' ? ' selected' : '') + '>United Kingdom</option>'
    content << '  </select>'
    content << '  <select name="status">'
    content << '    <option value="">All Statuses</option>'
    content << '    <option value="active"' + (@filters[:status] == 'active' ? ' selected' : '') + '>Active</option>'
    content << '    <option value="inactive"' + (@filters[:status] == 'inactive' ? ' selected' : '') + '>Inactive</option>'
    content << '    <option value="pilot"' + (@filters[:status] == 'pilot' ? ' selected' : '') + '>Pilot</option>'
    content << '    <option value="scaffold"' + (@filters[:status] == 'scaffold' ? ' selected' : '') + '>Scaffold</option>'
    content << '    <option value="research"' + (@filters[:status] == 'research' ? ' selected' : '') + '>Research</option>'
    content << '  </select>'
    content << '  <input type="text" name="search" placeholder="Search programs..." value="' + (@filters[:search] || '') + '">'
    content << '  <button type="submit">Filter</button>'
    content << '</form>'
    content << '</div>'

    # Results table
    content << '<div class="results">'
    content << '<table>'
    content << '<thead>'
    content << '<tr>'
    content << '<th>Country</th>'
    content << '<th>Program</th>'
    content << '<th>Method</th>'
    content << '<th>Active Adapter</th>'
    content << '<th>Status</th>'
    content << '<th>Requirements</th>'
    content << '<th>Profiles</th>'
    content << '<th>Actions</th>'
    content << '</tr>'
    content << '</thead>'
    content << '<tbody>'
    
    @country_programs.each do |program|
      content << '<tr>'
      content << "<td>#{program.country_code}</td>"
      content << "<td>#{program.name}</td>"
      content << "<td>#{program.method_name || 'N/A'}</td>"
      content << "<td>#{program.active_adapter_version || 'N/A'}</td>"
      content << "<td><span class=\"status-badge status-#{program.status.downcase}\">#{program.status}</span></td>"
      content << "<td>#{program.requirements_count || 0}</td>"
      content << "<td>#{program.profiles_count || 0}</td>"
      content << "<td><a href=\"/country_programs/#{program.id}\">View</a></td>"
      content << '</tr>'
    end
    
    content << '</tbody>'
    content << '</table>'
    content << '</div>'
    content << '</div>'
    content.html_safe
  end
end
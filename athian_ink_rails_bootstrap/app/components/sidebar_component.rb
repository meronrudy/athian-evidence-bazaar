class SidebarComponent < ViewComponent::Base
  def call
    content_tag :aside, class: "app-sidebar d-none d-lg-flex flex-column" do
      concat content_tag(:div, "Evidence bazaar", class: "sidebar-kicker")
      concat content_tag(:nav, class: "nav nav-pills flex-column gap-1") do
        concat render_links
      end
      concat content_tag(:div, "Truth boundary
This UI orchestrates and explains. The receipt and released verifier remain authoritative.", class: "sidebar-note mt-auto")
      concat content_tag(:div, "Strategic map", class: "sidebar-note mt-3")
    end
  end

  private
    def links
      [
        ["Overview", root_path, "01"],
        ["EVIDENCE", nil, "02"],
        ["Projects", projects_path, "02-01"],
        ["Evidence", nil, "02-02"],
        ["Reviews", nil, "02-03"],
        ["Artifacts", nil, "02-04"],
        ["PROGRAMS", nil, "03"],
        ["Country Programs", agevidence_country_programs_path, "03-01"],
        ["Methodologies", nil, "03-02"],
        ["DEVELOPER", nil, "04"],
        ["Integrations", integrations_events_path, "04-01"],
        ["API & Webhooks", nil, "04-02"],
        ["Developer Console", agevidence_developer_os_path, "04-03"],
        ["VERIFY", nil, "05"],
        ["Verification", verifier_console_path, "05-01"]
      ]
    end

    def render_links
      links.each do |label, path, index|
        if path.nil?
          concat content_tag(:div, label, class: "nav-header")
        else
          concat link_to path, class: "nav-link #{'active' if current_page?(path)}" do
            concat content_tag(:span, index, class: "nav-index")
            concat content_tag(:span, label)
          end
        end
      end
    end
  end
end
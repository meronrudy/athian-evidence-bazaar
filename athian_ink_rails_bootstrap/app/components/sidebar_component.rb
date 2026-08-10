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
        ["AgEvidence Launchpad", agevidence_root_path, "02-01"],
        ["Projects", agevidence_developer_projects_path, "02-02"],
        ["Evidence Explorer", evidence_index_path, "02-03"],
        ["Integration Inbox", integrations_events_path, "02-04"],
        ["POLICY", nil, "03"],
        ["Country Programs", agevidence_country_programs_path, "03-01"],
        ["Protocols", protocols_path, "03-02"],
        ["Methodology Migration", methodology_migrations_path, "03-03"],
        ["RELIANCE", nil, "04"],
        ["Determinations", agevidence_determinations_path, "04-01"],
        ["Bundle Builder", bundle_exports_path, "04-02"],
        ["VVB Console", verifier_console_path, "04-03"],
        ["Public Verification", public_verifier_path, "04-04"],
        ["SYSTEM", nil, "05"],
        ["Developer OS", agevidence_developer_os_path, "05-01"],
        ["API & Webhooks", developer_dashboard_index_path, "05-02"],
        ["Producer Ledger", producer_payments_path, "05-03"],
        ["Evidence Marketplace", evidence_marketplace_index_path, "05-04"]
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

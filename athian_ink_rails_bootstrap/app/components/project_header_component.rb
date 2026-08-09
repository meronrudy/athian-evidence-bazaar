class ProjectHeaderComponent < ViewComponent::Base
  def initialize(project)
    @project = project
  end

  def call
    content_tag :div, class: "project-header" do
      concat content_tag(:div, class: "project-title") do
        concat content_tag(:h1, @project.name)
        concat content_tag(:div, @project.description)
      end
      concat content_tag(:div, class: "project-meta") do
        concat content_tag(:div, "#{@project.organization} / #{@project.country} / #{@project.industry}")
        concat content_tag(:div, "Evidence readiness: #{@project.evidence_readiness_percentage}%")
        concat content_tag(:div, "Open gaps: #{@project.open_gaps}")
        concat content_tag(:div, "Review status: #{@project.review_status}")
        concat content_tag(:div, "Artifact status: #{@project.artifact_status}")
        concat content_tag(:div, "Verification: #{@project.verification_status}")
      end
    end
  end
end
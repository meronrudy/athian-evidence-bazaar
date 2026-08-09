class ProjectDashboardComponent < ViewComponent::Base
  def initialize
    @projects = Project.all.order(created_at: :desc)
  end

  def call
    content_tag :div, class: "project-dashboard" do
      h2 "Projects"
      ul do
        @projects.each do |project|
          li do
            link_to project_path(project), class: "project-tile" do
              span project.name.truncate(20)
              span project.evidence_readiness_percentage.round(1) + "%"
            end
          end
        end
      end
    end
  end
end
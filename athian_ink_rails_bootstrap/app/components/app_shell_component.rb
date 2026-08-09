class AppShellComponent < ViewComponent::Base
  def initialize(container: :main)
    @container = container
  end

  def call
    content_tag :div, class: "app-shell" do
      concat render SidebarComponent.new
      concat content_tag(:main, class: "app-main") do
        concat render Shared::FlashComponent.new if respond_to?(:render) && defined?(Shared::FlashComponent)
        concat yield
      end
    end
  end
end
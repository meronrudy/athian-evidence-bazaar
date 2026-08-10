module ViewComponent
  class Base
    attr_reader :view_context

    def render_in(view_context, &block)
      @view_context = view_context
      output = respond_to?(:call) ? call(&block) : render
      output.respond_to?(:html_safe) ? output.html_safe : output
    end

    def format
      :html
    end

    private

    def method_missing(method_name, ...)
      return super unless view_context&.respond_to?(method_name)

      view_context.public_send(method_name, ...)
    end

    def respond_to_missing?(method_name, include_private = false)
      view_context&.respond_to?(method_name, include_private) || super
    end
  end
end

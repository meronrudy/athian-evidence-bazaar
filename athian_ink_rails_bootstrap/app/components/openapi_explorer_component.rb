class OpenapiExplorerComponent < ViewComponent::Base
  def initialize(schemas:)
    @schemas = schemas
  end

  def render
    content = '<h3>OpenAPI Explorer</h3>'
    content << '<div class="openapi-explorer">'
    content << '<div class="schema-list">'
    content << '<h4>Available Schemas</h4>'
    content << '<ul>'
    @schemas.each do |schema|
      content << "<li>#{schema.name} (v#{schema.version})</li>"
    end
    content << '</ul>'
    content << '</div>'

    # Schema details section
    content << '<div class="schema-details">'
    content << '<h4>Selected Schema Details</h4>'
    if @schemas.any?
      schema = @schemas.first
      content << %(<pre>{
      "name": "#{schema.name}",
      "version": "#{schema.version}",
      "type": "#{schema.type}",
      "endpoints": [
        {"method": "GET", "path": "/api/v1/schemas/#{schema.name}/#{schema.version}", "description": "Retrieve schema details"},
        {"method": "POST", "path": "/api/v1/schemas", "description": "Create new schema"}
      ]
    }</pre>)
    else
      content << '<p>No schemas yet.</p>'
    end
    content << '</div>'

    # Schema creation form
    content << '<h4>Create New Schema</h4>'
    content << '<form data-action="schemas#create" data-method="post">'
    content << '  <input type="text" name="schema[name]" placeholder="Schema name" required>'
    content << '  <input type="text" name="schema[Type]" placeholder="Type" required>'
    content << '  <input type="text" name="schema[Version]" placeholder="Version" required>'
    content << '  <textarea name="schema[Definition]" placeholder="JSON definition" required></textarea>'
    content << '  <button type="submit">Create</button>'
    content << '</form>'

    content.html_safe
  end
end

class SchemaBrowserComponent < ViewComponent::Base
  def initialize(schemas:)
    @schemas = schemas
  end

  def render
    content = '<h3>Schema Browser</h3>'
    content << '<div class="schema-browser">'
    content << '<table>'
    content << '<thead><tr>'
    content << '<th>Name</th>'
    content << '<th>Version</th>'
    content << '<th>Type</th>'
    content << '<th>Created At</th>'
    content << '</tr></thead>'
    content << '<tbody>'
    @schemas.each do |schema|
      content << '<tr>'
      content << "<td>#{schema.name}</td>"
      content << "<td>#{schema.version}</td>"
      content << "<td>#{schema.type}</td>"
      content << "<td>#{schema.created_at}</td>"
      content << '</tr>'
    end
    content << '</tbody>'
    content << '</table>'
    content << '</div>'

    # Simple create form
    content << '<h4>Create New Schema</h4>'
    content << '<form data-action="schemas#create" data-method="post">'
    content << '  <input type="text" name="schema[name]" placeholder="Schema name" required>'
    content << '  <input type="text" name="schema[type]" placeholder="Type" required>'
    content << '  <input type="text" name="schema[version]" placeholder="Version" required>'
    content << '  <textarea name="schema[definition]" placeholder="JSON definition" required></textarea>'
    content << '  <button type="submit">Create</button>'
    content << '</form>'

    content.html_safe
  end
end
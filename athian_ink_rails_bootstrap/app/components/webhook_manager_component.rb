class WebhookManagerComponent < ViewComponent::Base
  def initialize(webhooks:)
    @webhooks = webhooks
  end

  def render
    content = ''
    content << '<h3>Webhook Configuration</h3>'
    content << '<div class="webhook-list">'
    content << '<table>'
    content << '<thead><tr>'
    content << '<th>Event</th>'
    content << '<th>URL</th>'
    content << '<th>Active</th>'
    content << '<th>Created At</th>'
    content << '</tr></thead>'
    content << '<tbody>'
    @webhooks.each do |webhook|
      content << '<tr>'
      content << "<td>#{webhook.event}</td>"
      content << "<td>#{webhook.url}</td>"
      content << "<td>#{webhook.active ? 'Active' : 'Inactive'}</td>"
      content << "<td>#{webhook.created_at}</td>"
      content << '</tr>'
    end
    content << '</tbody>'
    content << '</table>'
    content << '</div>'

    # Simple create form
    content << '<h4>Create New Webhook</h4>'
    content << '<form data-action="webhooks#create" data-method="post">'
    content << '  <input type="text" name="webhook[event]" placeholder="Event name" required>'
    content << '  <input type="url" name="webhook[url]" placeholder="Webhook URL" required>'
    content << '  <input type="text" name="webhook[description]" placeholder="Description">'
    content << '  <button type="submit">Create</button>'
    content << '</form>'

    content.html_safe
  end
end
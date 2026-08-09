class ApiKeyManagerComponent < ViewComponent::Base
  def initialize(api_keys:)
    @api_keys = api_keys
  end

  def render
    # Render API key management UI
    html = ""
    # List existing API keys
    html << "<h3>API Keys</h3>"
    html << "<ul>"
    @api_keys.each do |api_key|
      html << "<li>#{api_key.masked_key} - #{api_key.name}</li>"
    end
    html << "</ul>"

    # Create new API key form
    html << "<h4>Create New API Key</h4>"
    html << "<form data-action="api_keys#create" data-method="post">"
    html << "  <input type="text" name="api_key[name]" placeholder="Key name">"
    html << "  <button type="submit">Create</button>"
    html << "</form>"

    # Revoke API key buttons
    @api_keys.each do |api_key|
      html << "<button data-action="api_keys#revoke" data-method="delete" data-id="#{api_key.id}">Revoke #{api_key.masked_key}</button>"
    end
    html << "</form>"
    html
  end
end
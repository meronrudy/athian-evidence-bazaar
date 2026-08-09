class ApiLogManagerComponent < ViewComponent::Base
  def initialize(api_logs:)
    @api_logs = api_logs
  end

  def render
    content = ''
    content << '<h3>API Logs</h3>'
    content << '<div class="log-table">'
    content << '<table>'
    content << '<thead><tr>'
    content << '<th>ID</th>'
    content << '<th>Endpoint</th>'
    content << '<th>Method</th>'
    content << '<th>Status</th>'
    content << '<th>Created At</th>'
    content << '</tr></thead>'
    content << '<tbody>'
    @api_logs.each do |log|
      content << '<tr>'
      content << "<td>#{log.id}</td>"
      content << "<td>#{log.endpoint}</td>"
      content << "<td>#{log.method}</td>"
      content << "<td>#{log.status}</td>"
      content << "<td>#{log.created_at}</td>"
      content << '</tr>'
    end
    content << '</tbody>'
    content << '</table>'
    content << '</div>'
    content.html_safe
  end
end
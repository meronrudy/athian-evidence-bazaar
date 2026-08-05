module Integrations
  HandlerResult = Struct.new(
    :projections,
    :receipt_requests,
    :warnings,
    :external_mappings,
    keyword_init: true
  )
end

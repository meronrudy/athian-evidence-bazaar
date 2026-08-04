module ApplicationHelper
  def strategic_moves
    InkReceipts::STRATEGIC_MOVES
  end

  def lifecycle_badge_class(state)
    {
      "draft" => "text-bg-secondary",
      "observed" => "text-bg-info",
      "validated" => "text-bg-primary",
      "attested" => "text-bg-warning",
      "sealed" => "text-bg-success",
      "superseded" => "text-bg-dark",
      "revoked" => "text-bg-danger",
      "expired" => "text-bg-secondary",
      "renewed" => "text-bg-success"
    }.fetch(state.to_s, "text-bg-secondary")
  end

  def verification_badge_class(status)
    {
      "valid" => "text-bg-success",
      "invalid" => "text-bg-danger",
      "indeterminate" => "text-bg-warning"
    }.fetch(status.to_s, "text-bg-secondary")
  end

  def severity_badge_class(severity)
    {
      "critical" => "text-bg-danger",
      "high" => "text-bg-danger",
      "medium" => "text-bg-warning",
      "low" => "text-bg-info"
    }.fetch(severity.to_s, "text-bg-secondary")
  end

  def lifecycle_reached?(current_state, target_state)
    core = %w[draft observed validated attested sealed]
    current_index = core.index(current_state.to_s)
    target_index = core.index(target_state.to_s)
    return true if %w[superseded revoked expired renewed].include?(current_state.to_s)
    return false unless current_index && target_index

    target_index <= current_index
  end

  def compact_digest(value, length: 12)
    return "—" if value.blank?

    "#{value.to_s.first(length)}…#{value.to_s.last(6)}"
  end

  def money(amount, currency = "USD")
    number_to_currency(amount, unit: currency == "USD" ? "$" : "#{currency} ")
  end

  def evidence_icon(type)
    {
      "feed_invoice" => "FI",
      "lab_report" => "LAB",
      "gps_data" => "GPS",
      "model_run" => "MOD",
      "satellite_image" => "SAT",
      "vvb_determination" => "VVB",
      "registry_record" => "REG",
      "payment_advice" => "ACH"
    }.fetch(type.to_s, "EV")
  end

  def receipt_cli_command(receipt)
    "ink verify receipt-#{receipt.id}.json --policy trust-policy.json"
  end
end

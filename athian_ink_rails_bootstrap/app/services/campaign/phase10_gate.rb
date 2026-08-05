module Campaign
  class Phase10Gate
    PRODUCT_CODE = "evidence_architecture_sprint"

    Disabled = Class.new(StandardError)

    def self.enabled?
      new.enabled?
    end

    def enabled?
      proof_handoff.present?
    end

    def ensure_enabled!
      return true if enabled?

      raise Disabled, "Phase 10 is gated until a paid Architecture Sprint has contracted and collected value."
    end

    def proof_handoff
      @proof_handoff ||= Campaign::CommercialHandoff
                         .where(product_code: PRODUCT_CODE)
                         .where("contracted_value_cents > 0")
                         .where("cash_collected_cents > 0")
                         .order(cash_recorded_at: :asc, updated_at: :asc)
                         .first
    end

    def status_payload
      {
        enabled: enabled?,
        proof_product_code: PRODUCT_CODE,
        proof_handoff_id: proof_handoff&.external_id,
        requirement: "One paid Architecture Sprint with bounded contracted and collected cash signals."
      }
    end
  end
end

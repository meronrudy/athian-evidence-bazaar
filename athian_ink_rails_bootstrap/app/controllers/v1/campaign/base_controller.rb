module V1
  module Campaign
    class BaseController < ActionController::API
      private

      def find_account!
        external_id = params[:account_external_id] || params[:external_id] || params[:account_id]
        ::Campaign::Account.find_by!(external_id: external_id)
      end

      def account_payload(account, detail: false)
        payload = {
          account_id: account.external_id,
          name: account.name,
          domain: account.domain,
          country_code: account.country_code,
          subsector: account.subsector,
          funding_stage: account.funding_stage,
          capital_raised_cents: account.capital_raised_cents,
          status: account.status,
          qualification_level: account.qualification_level,
          priority_score: account.priority_score,
          authoritative_system: account.authoritative_system,
          evidence_obligation_code: account.evidence_obligation_code,
          evidence_obligation_summary: account.evidence_obligation_summary,
          salesforce_account_id: account.salesforce_account_id,
          apollo_account_id: account.apollo_account_id,
          developer_account_id: account.developer_account_id,
          system_of_record: {
            campaign: "Campaign attribution and routing",
            developer_account: "AgEvidence",
            contact_enrichment: "Apollo",
            opportunity: "Salesforce",
            evidence: "AgEvidence"
          },
          authority_boundary: "Campaign state does not imply scientific approval, payment, or institutional reliance."
        }
        return payload unless detail

        payload.merge(
          contacts: account.contact_refs.order(:id).map { |contact| contact_payload(contact) },
          activations: account.activation_paths.order(updated_at: :desc).map { |activation| activation_payload(activation) },
          qualifications: account.technical_qualifications.order(created_at: :desc).map { |qualification| qualification_payload(qualification) },
          handoffs: account.commercial_handoffs.order(created_at: :desc).map { |handoff| handoff_payload(handoff) }
        )
      end

      def contact_payload(contact)
        {
          contact_id: contact.external_id,
          display_name: contact.display_name,
          role_category: contact.role_category,
          email_domain: contact.email_domain,
          salesforce_contact_id: contact.salesforce_contact_id,
          apollo_person_id: contact.apollo_person_id,
          technical_authority: contact.technical_authority,
          commercial_authority: contact.commercial_authority,
          scientific_authority: contact.scientific_authority,
          contactability_status: contact.contactability_status,
          last_enriched_at: contact.last_enriched_at&.iso8601,
          last_synced_at: contact.last_synced_at&.iso8601,
          system_of_record: "Apollo for enrichment; Salesforce for durable contact identity"
        }
      end

      def activation_payload(activation)
        {
          activation_id: activation.external_id,
          account_id: activation.campaign_account.external_id,
          path_type: activation.path_type,
          status: activation.status,
          repository_sha: activation.repository_sha,
          guide_path: activation.guide_path,
          sdk_version: activation.sdk_version,
          cli_version: activation.cli_version,
          developer_project_external_id: activation.developer_project_external_id,
          invited_at: activation.invited_at&.iso8601,
          started_at: activation.started_at&.iso8601,
          completed_at: activation.completed_at&.iso8601,
          failed_at: activation.failed_at&.iso8601,
          failure_code: activation.failure_code,
          support_minutes: activation.support_minutes,
          authority_boundary: "Attribution metadata only; does not alter evidence canonicalization or review outcomes."
        }
      end

      def qualification_payload(qualification)
        {
          qualification_id: qualification.external_id,
          account_id: qualification.campaign_account.external_id,
          developer_project_id: qualification.developer_project_id,
          status: qualification.status,
          qualification_level: qualification.qualification_level,
          authoritative_system_confirmed: qualification.authoritative_system_confirmed,
          supported_event_count: qualification.supported_event_count,
          required_event_count: qualification.required_event_count,
          evidence_gap_count: qualification.evidence_gap_count,
          unreviewed_candidate_count: qualification.unreviewed_candidate_count,
          country_code: qualification.country_code,
          country_adapter_identifier: qualification.country_adapter_identifier,
          named_obligation_code: qualification.named_obligation_code,
          named_relying_party_type: qualification.named_relying_party_type,
          qualification_reason: qualification.qualification_reason,
          qualified_at: qualification.qualified_at&.iso8601,
          snapshot: qualification.snapshot_json,
          authority_boundary: "Immutable campaign snapshot derived from linked repository records."
        }
      end

      def handoff_payload(handoff)
        {
          handoff_id: handoff.external_id,
          account_id: handoff.campaign_account.external_id,
          qualification_id: handoff.campaign_technical_qualification.external_id,
          product_code: handoff.product_code,
          status: handoff.status,
          scope_digest: handoff.scope_digest,
          planning_value_cents: handoff.planning_value_cents,
          contracted_value_cents: handoff.contracted_value_cents,
          cash_collected_cents: handoff.cash_collected_cents,
          currency: handoff.currency,
          salesforce_opportunity_id: handoff.salesforce_opportunity_id,
          salesforce_proposal_id: handoff.salesforce_proposal_id,
          proposal_reference: handoff.proposal_reference,
          proposal_terms_digest: handoff.proposal_terms_digest,
          contract_reference: handoff.contract_reference,
          contract_terms_digest: handoff.contract_terms_digest,
          invoice_reference: handoff.invoice_reference,
          cash_collection_reference: handoff.cash_collection_reference,
          revenue_system: handoff.revenue_system,
          sent_at: handoff.sent_at&.iso8601,
          accepted_at: handoff.accepted_at&.iso8601,
          contracted_at: handoff.contracted_at&.iso8601,
          cash_recorded_at: handoff.cash_recorded_at&.iso8601,
          last_revenue_signal_at: handoff.last_revenue_signal_at&.iso8601,
          authority_boundary: "Salesforce governs opportunity, contract, forecast, and collection references; it cannot alter evidence qualification."
        }
      end

      def render_error(code, status:, message: nil)
        render json: { error: { code: code, message: message.presence || code.to_s.humanize } }, status: status
      end
    end
  end
end

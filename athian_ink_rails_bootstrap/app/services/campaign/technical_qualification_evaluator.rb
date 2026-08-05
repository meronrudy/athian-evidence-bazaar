module Campaign
  class TechnicalQualificationEvaluator
    def initialize(campaign_account:, developer_project: nil, options: {})
      @campaign_account = campaign_account
      @developer_project = developer_project || campaign_account.developer_account&.developer_projects&.order(updated_at: :desc)&.first
      @options = options.to_h.deep_stringify_keys
    end

    def call
      snapshot = build_snapshot
      level = determine_level(snapshot)
      status = level == "unqualified" ? "evaluated" : "qualified"

      qualification = campaign_account.technical_qualifications.create!(
        developer_project: developer_project,
        status: status,
        qualification_level: level,
        authoritative_system_confirmed: snapshot.fetch("authoritative_system_confirmed"),
        supported_event_count: snapshot.fetch("supported_event_count"),
        required_event_count: snapshot.fetch("required_event_count"),
        evidence_gap_count: snapshot.fetch("evidence_gap_count"),
        unreviewed_candidate_count: snapshot.fetch("unreviewed_candidate_count"),
        country_code: snapshot.fetch("country_code"),
        country_adapter_identifier: snapshot["country_adapter_identifier"],
        named_obligation_code: snapshot["named_obligation_code"],
        named_relying_party_type: snapshot["named_relying_party_type"],
        qualification_reason: reason_for(level, snapshot),
        qualified_at: status == "qualified" ? Time.current : nil,
        country_adapter_readiness: snapshot["country_adapter_readiness"],
        institution_profile: snapshot["institution_profile"],
        obligation_profile: snapshot["obligation_profile"],
        local_evidence_gap_count: snapshot.fetch("local_evidence_gap_count"),
        cross_country_portability_result: snapshot["cross_country_portability_result"],
        snapshot_json: snapshot
      )
      campaign_account.sync_qualification!(level)
      qualification
    end

    private

    attr_reader :campaign_account, :developer_project, :options

    def build_snapshot
      source_records = developer_project ? developer_project.source_records.to_a : []
      model_runs = developer_project ? developer_project.model_runs.includes(:evidence_gaps, :evidence_candidates).to_a : []
      evidence_gaps = model_runs.flat_map(&:evidence_gaps)
      unreviewed = model_runs.flat_map(&:evidence_candidates).count { |candidate| candidate.review_status == "review_required" }
      country_determination = developer_project&.country_determinations&.includes(:country_adapter)&.order(evaluated_at: :desc)&.first
      artifact_orders = developer_project ? developer_project.artifact_orders.to_a : []
      reliance_events = developer_project ? Agevidence::RelianceEvent.joins(:artifact_engagement).where(agevidence_artifact_engagements: { developer_project_id: developer_project.id }).to_a : []
      accepted_events = accepted_events_for_project
      activation_completed = campaign_account.activation_paths.where(path_type: "cli_project_4030", status: "completed").exists?
      authoritative_source = options["authoritative_system"].presence || campaign_account.authoritative_system.presence || source_records.map(&:source_system).compact.first

      {
        "campaign_account_id" => campaign_account.external_id,
        "developer_project_id" => developer_project&.id,
        "developer_project_present" => developer_project.present?,
        "source_record_ids" => source_records.map(&:id),
        "source_record_count" => source_records.size,
        "accepted_integration_event_ids" => accepted_events.map(&:external_event_id),
        "supported_event_count" => source_records.size + accepted_events.size,
        "required_event_count" => options["required_event_count"].presence.to_i,
        "evidence_gap_ids" => evidence_gaps.map(&:id),
        "evidence_gap_count" => evidence_gaps.size,
        "material_evidence_gap_count" => evidence_gaps.count { |gap| %w[material critical].include?(gap.severity) },
        "reusable_mapping_identified" => ActiveModel::Type::Boolean.new.cast(options["reusable_mapping_identified"]),
        "unreviewed_candidate_count" => unreviewed,
        "country_code" => (options["country_code"].presence || country_determination&.country_program&.country_code || campaign_account.country_code).to_s.upcase,
        "country_adapter_identifier" => country_determination&.country_adapter&.adapter_id || options["country_adapter_identifier"],
        "authoritative_system_confirmed" => authoritative_source.present?,
        "authoritative_system" => authoritative_source,
        "named_obligation_code" => options["named_obligation_code"].presence || campaign_account.evidence_obligation_code,
        "named_relying_party_type" => options["named_relying_party_type"].presence || options["relying_party_type"],
        "reliance_event_ids" => reliance_events.map(&:id),
        "artifact_order_ids" => artifact_orders.map(&:id),
        "product_code" => options["product_code"].presence,
        "scope_estimate" => options["scope_estimate"].presence,
        "accountable_buyer_or_sponsor" => options["accountable_buyer_or_sponsor"].presence,
        "timing_window" => options["timing_window"].presence,
        "permitted_commercial_handoff" => ActiveModel::Type::Boolean.new.cast(options["permitted_commercial_handoff"]),
        "activation_completed" => activation_completed,
        "synthetic_only" => synthetic_only?(source_records),
        "country_adapter_readiness" => options["country_adapter_readiness"],
        "institution_profile" => options["institution_profile"],
        "obligation_profile" => options["obligation_profile"],
        "local_evidence_gap_count" => options["local_evidence_gap_count"].to_i,
        "cross_country_portability_result" => options["cross_country_portability_result"],
        "evaluated_at" => Time.current.iso8601
      }
    end

    def determine_level(snapshot)
      return "commercially_qualified" if commercially_qualified?(snapshot)
      return "reliance_qualified" if reliance_qualified?(snapshot)
      return "evidence_qualified" if evidence_qualified?(snapshot)
      return "developer_activated" if developer_activated?(snapshot)

      "unqualified"
    end

    def developer_activated?(snapshot)
      snapshot["developer_project_present"] ||
        snapshot["source_record_count"].positive? ||
        snapshot["accepted_integration_event_ids"].any? ||
        snapshot["activation_completed"]
    end

    def evidence_qualified?(snapshot)
      snapshot["authoritative_system_confirmed"] &&
        snapshot["supported_event_count"].positive? &&
        (snapshot["material_evidence_gap_count"].positive? || snapshot["reusable_mapping_identified"]) &&
        !snapshot["synthetic_only"]
    end

    def reliance_qualified?(snapshot)
      evidence_qualified?(snapshot) &&
        snapshot["named_relying_party_type"].present? &&
        snapshot["named_obligation_code"].present? &&
        snapshot["reliance_event_ids"].any?
    end

    def commercially_qualified?(snapshot)
      reliance_qualified?(snapshot) &&
        snapshot["product_code"].present? &&
        snapshot["scope_estimate"].present? &&
        snapshot["accountable_buyer_or_sponsor"].present? &&
        snapshot["timing_window"].present? &&
        snapshot["permitted_commercial_handoff"]
    end

    def reason_for(level, snapshot)
      case level
      when "commercially_qualified"
        "Reliance-qualified account has bounded product, scope, buyer or sponsor, timing window, and permitted handoff."
      when "reliance_qualified"
        "Evidence-qualified account has named relying-party type, named obligation, and recorded reliance event."
      when "evidence_qualified"
        "Account has authoritative source system, real source or event, and concrete evidence gap or reusable mapping."
      when "developer_activated"
        "Account has concrete Developer OS activation through project, source, event, or Project 4030 replay."
      else
        "No evidence-grounded qualification threshold met."
      end
    end

    def synthetic_only?(source_records)
      return false if source_records.empty?

      source_records.all? { |record| ActiveModel::Type::Boolean.new.cast(record.metadata_json["synthetic_demo"]) }
    end

    def accepted_events_for_project
      return [] unless developer_project

      external_project_ids = ExternalObjectMapping.where(
        internal_record_type: "Agevidence::DeveloperProject",
        internal_record_id: developer_project.id
      ).pluck(:external_object_id)
      external_project_ids << developer_project.id.to_s
      IntegrationEvent.where(processing_status: %w[accepted processed]).select do |event|
        external_project_ids.include?(event.correlation["project_id"]) ||
          external_project_ids.include?(event.external_object_id)
      end
    end
  end
end

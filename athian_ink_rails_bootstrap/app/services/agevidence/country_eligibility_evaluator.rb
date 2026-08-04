module Agevidence
  class CountryEligibilityEvaluator
    STATUSES = Agevidence::DeveloperProject::COUNTRY_DETERMINATION_STATUSES
    DETERMINATION_ROLE = "Athian compatibility assessment only".freeze

    def initialize(project:)
      @project = project
    end

    def call
      return unassigned unless program
      return method_extension_required unless adapter && method_version

      excluded = excluded_contexts
      missing = missing_evidence
      status = determine_status(excluded: excluded, missing: missing)

      {
        country: program.code,
        country_name: program.country_name,
        adapter_id: adapter.adapter_id,
        adapter_version: adapter.version,
        method: method_version.country_method.name,
        method_code: method_version.country_method.code,
        method_version: method_version.version,
        method_status: method_version.status,
        status: status,
        eligible_activity: rules["eligible_activity"],
        excluded_contexts: excluded,
        missing_evidence: missing,
        authority: method_version.country_method.authority,
        determination_role: DETERMINATION_ROLE,
        limitations: Array(adapter.limitations) + [
          "Final project eligibility, verification, registration, and credit or claim acceptance remain with the applicable authorities and relying institutions."
        ],
        evaluated_at: Time.current.iso8601
      }
    end

    private

    attr_reader :project

    def program
      @program ||= project.country_program
    end

    def adapter
      @adapter ||= program&.default_adapter
    end

    def method_version
      @method_version ||= project.protocol&.country_method_version || adapter&.country_method_version || program&.current_method_version
    end

    def rules
      @rules ||= (adapter&.eligibility_rules || {}).stringify_keys
    end

    def context
      @context ||= project.country_context.stringify_keys
    end

    def excluded_contexts
      explicit = Array(rules["excluded_contexts"])
      matched = explicit.select do |excluded|
        context.values.flatten.compact.map { |value| value.to_s.downcase }.include?(excluded.to_s.downcase)
      end

      allowed = (rules["allowed_contexts"] || {}).stringify_keys
      allowed.each do |key, values|
        next if context[key].blank?
        next if Array(values).map(&:to_s).include?(context[key].to_s)

        matched << "#{key}=#{context[key]}"
      end

      matched.uniq
    end

    def missing_evidence
      required = Array(rules["required_evidence"])
      available = project.source_documents.flat_map do |document|
        [document[:document_id], document[:evidence_type]].compact.map { |value| value.to_s.downcase }
      end

      required.reject do |requirement|
        token = requirement.to_s.downcase
        available.any? { |value| value.include?(token) || token.include?(value) }
      end
    end

    def determine_status(excluded:, missing:)
      return "outside_current_method" if excluded.any?
      return "method_extension_required" unless %w[pilot government_review accepted active].include?(method_version.status)
      return "eligible_with_conditions" if missing.any?

      "eligible"
    end

    def unassigned
      {
        country: nil,
        status: "unassigned",
        determination_role: DETERMINATION_ROLE,
        limitations: ["Assign a country program before evaluating local method compatibility."],
        evaluated_at: Time.current.iso8601
      }
    end

    def method_extension_required
      {
        country: program.code,
        country_name: program.country_name,
        status: "method_extension_required",
        determination_role: DETERMINATION_ROLE,
        limitations: ["No versioned country adapter and method pair is available for this project."],
        evaluated_at: Time.current.iso8601
      }
    end
  end
end

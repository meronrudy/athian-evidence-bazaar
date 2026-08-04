module Agevidence
  class CountryEligibilityEvaluator
    CONTRACT = "athian.country_determination.v1"

    def initialize(project:, country_adapter:)
      @project = project
      @country_adapter = country_adapter
      @manifest = country_adapter.manifest
    end

    def call
      {
        "contract" => CONTRACT,
        "project_id" => "project-#{project.id}",
        "country_code" => country_adapter.country_code,
        "adapter_id" => country_adapter.adapter_id,
        "adapter_version" => country_adapter.version,
        "method_id" => country_adapter.country_method_version.method_id,
        "method_version" => country_adapter.country_method_version.version,
        "status" => status,
        "matched_context" => matched_context,
        "excluded_contexts" => excluded_contexts,
        "required_evidence" => required_evidence,
        "missing_evidence" => missing_evidence,
        "unresolved_conflicts" => unresolved_conflicts,
        "authority" => manifest.fetch("method").fetch("authority"),
        "determination_role" => "Athian compatibility assessment only",
        "policy_extensions" => policy_extensions,
        "registry_mapping" => registry_mapping,
        "limitations" => country_adapter.limitations,
        "evaluated_at" => Time.current.iso8601
      }
    end

    private

    attr_reader :project, :country_adapter, :manifest

    def status
      return "unassigned" if project.country_context.blank?
      return "outside_current_method" if excluded_contexts.any?
      return "method_extension_required" unless required_context_met?
      return "eligible" if missing_evidence.empty? && unresolved_conflicts.empty?
      return "insufficient_evidence" if available_evidence.empty?

      "eligible_with_conditions"
    end

    def matched_context
      required_context.each_with_object({}) do |(key, allowed), result|
        value = project.country_context[key] || project.country_context[key.to_s]
        result[key] = value if Array(allowed).include?(value)
      end
    end

    def excluded_contexts
      excluded_context.each_with_object([]) do |(key, values), result|
        value = project.country_context[key] || project.country_context[key.to_s]
        result << { key => value } if Array(values).include?(value)
      end
    end

    def required_context_met?
      required_context.all? do |key, allowed|
        value = project.country_context[key] || project.country_context[key.to_s]
        Array(allowed).include?(value)
      end
    end

    def missing_evidence
      required_evidence - available_evidence
    end

    def unresolved_conflicts
      project.model_runs.flat_map do |run|
        run.evidence_gaps.where.not(resolution_status: "resolved").pluck(:requirement)
      end.uniq
    end

    def required_evidence
      country_adapter.required_evidence
    end

    def available_evidence
      project.source_documents.flat_map do |document|
        [
          document[:global_evidence_type],
          document["global_evidence_type"],
          document[:evidence_type],
          document["evidence_type"]
        ]
      end.compact.uniq
    end

    def required_context
      manifest.fetch("applicability").fetch("required_context")
    end

    def excluded_context
      manifest.fetch("applicability").fetch("excluded_context")
    end

    def policy_extensions
      {
        "claim_policy" => manifest.fetch("claim_policy").fetch("profile"),
        "verification_profile" => manifest.fetch("verification_profile").fetch("profile"),
        "data_policy" => manifest.fetch("data_policy").fetch("profile")
      }
    end

    def registry_mapping
      {
        "country_code" => country_adapter.country_code,
        "adapter_id" => country_adapter.adapter_id
      }
    end
  end
end

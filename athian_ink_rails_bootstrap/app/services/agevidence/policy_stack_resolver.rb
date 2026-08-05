module Agevidence
  class PolicyStackResolver
    RESOLUTION_CODES = {
      compatible: "compatible",
      extension_applied: "extension_applied",
      requirement_added: "requirement_added",
      requirement_overridden: "requirement_overridden",
      unresolved_conflict: "unresolved_conflict",
      superseded_policy: "superseded_policy",
      institution_specific_requirement: "institution_specific_requirement"
    }.freeze

    def initialize(country_adapter:, institution_profile: nil)
      @country_adapter = country_adapter
      @manifest = country_adapter.manifest
      @institution_profile = institution_profile
    end

    def call
      entries = [
        global_contract_entry,
        country_common_entry,
        profile_entry("methodology", manifest.fetch("claim_policy").fetch("profile")),
        profile_entry("verifier", manifest.fetch("verification_profile").fetch("profile")),
        profile_entry("data_policy", manifest.fetch("data_policy").fetch("profile"))
      ]
      entries << institution_entry if institution_profile.present?

      {
        "stack" => entries,
        "requirements" => entries.flat_map { |entry| Array(entry["requirements"]) }.uniq,
        "results" => resolution_results(entries),
        "unresolved_conflicts" => unresolved_conflicts(entries)
      }
    end

    private

    attr_reader :country_adapter, :manifest, :institution_profile

    def global_contract_entry
      PolicyProfile.new(
        profile_type: "global_contract",
        profile_id: manifest.fetch("global_contract").fetch("agricultural_vocabulary"),
        version: "v1",
        requirements: [
          manifest.fetch("global_contract").fetch("receipt_envelope"),
          manifest.fetch("global_contract").fetch("verifier_contract")
        ]
      ).to_h(layer: "global")
    end

    def country_common_entry
      PolicyProfile.new(
        profile_type: "methodology",
        profile_id: manifest.fetch("method").fetch("id"),
        version: manifest.fetch("method").fetch("version"),
        authority: manifest.fetch("method").fetch("authority"),
        requirements: country_adapter.required_evidence,
        limitations: country_adapter.limitations
      ).to_h(layer: "country")
    end

    def profile_entry(profile_type, profile_id)
      PolicyProfile.new(
        profile_type: profile_type,
        profile_id: profile_id,
        version: country_adapter.version,
        authority: manifest.fetch("method").fetch("authority")
      ).to_h(layer: "country")
    end

    def institution_entry
      PolicyProfile.new(
        profile_type: institution_profile.fetch("profile_type", "institution"),
        profile_id: institution_profile.fetch("profile_id", "ad-hoc-institution-profile"),
        version: institution_profile.fetch("version", "v1"),
        authority: institution_profile["authority"],
        requirements: institution_profile["requirements"],
        limitations: institution_profile["limitations"],
        conflicts: institution_profile["conflicts"]
      ).to_h(layer: "institution")
    end

    def resolution_results(entries)
      entries.flat_map do |entry|
        requirement_results = Array(entry["requirements"]).map do |requirement|
          code = entry["layer"] == "institution" ? RESOLUTION_CODES.fetch(:institution_specific_requirement) : RESOLUTION_CODES.fetch(:compatible)
          {
            "code" => code,
            "requirement" => requirement,
            "source_profile" => entry["profile_id"],
            "message" => "#{entry['profile_id']} contributes #{requirement}"
          }
        end
        conflict_results = Array(entry["conflicts"]).map do |conflict|
          {
            "code" => RESOLUTION_CODES.fetch(:unresolved_conflict),
            "requirement" => conflict,
            "source_profile" => entry["profile_id"],
            "message" => "#{entry['profile_id']} leaves #{conflict} unresolved"
          }
        end
        requirement_results + conflict_results
      end
    end

    def unresolved_conflicts(entries)
      entries.flat_map { |entry| Array(entry["conflicts"]) }.uniq
    end
  end
end

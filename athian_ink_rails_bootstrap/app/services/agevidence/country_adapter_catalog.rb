require "yaml"

module Agevidence
  class CountryAdapterCatalog
    REQUIRED_MANIFEST_KEYS = %w[
      adapter global_contract method applicability required_evidence claim_policy
      verification_profile data_policy artifact_profiles limitations
    ].freeze

    class << self
      def manifests
        Dir[root.join("*", "adapter.yml")].sort.map do |path|
          manifest = YAML.load_file(path)
          validate_manifest!(manifest)
          manifest.merge("slug" => File.basename(File.dirname(path)), "path" => path)
        end
      end

      def find(adapter_id)
        manifests.detect { |manifest| manifest.fetch("adapter").fetch("id") == adapter_id }
      end

      def artifact_profile(country_adapter, profile_id = nil)
        manifest = country_adapter.respond_to?(:manifest) ? country_adapter.manifest : country_adapter
        slug = manifest.fetch("slug", slug_for_manifest(manifest))
        selected = profile_id || Array(manifest.fetch("artifact_profiles")).first
        path = root.join(slug, "artifact_profiles", "#{selected}.yml")
        return default_artifact_profile(selected) unless File.exist?(path)

        YAML.load_file(path)
      end

      def sync!
        manifests.map { |manifest| sync_manifest!(manifest) }
      end

      def validate_manifest!(manifest)
        REQUIRED_MANIFEST_KEYS.each { |key| manifest.fetch(key) }
        manifest.fetch("adapter").fetch("id")
        manifest.fetch("adapter").fetch("version")
        manifest.fetch("adapter").fetch("country_code")
        manifest.fetch("method").fetch("id")
        manifest.fetch("method").fetch("version")
        manifest
      end

      private

      def sync_manifest!(manifest)
        adapter_data = manifest.fetch("adapter")
        method_data = manifest.fetch("method")

        program = CountryProgram.find_or_create_by!(
          country_code: adapter_data.fetch("country_code"),
          name: method_data.fetch("authority")
        ) do |record|
          record.program_type = "country_policy_adapter"
          record.authority_name = method_data.fetch("authority")
          record.status = adapter_data.fetch("status")
          record.description = "Data-driven AgEvidence country program projection."
        end

        method = program.country_methods.find_or_create_by!(method_id: method_data.fetch("id")) do |record|
          record.name = method_data.fetch("id").tr("-", " ")
          record.authority_name = method_data.fetch("authority")
          record.status = adapter_data.fetch("status")
        end

        method_version = method.country_method_versions.find_or_create_by!(version: method_data.fetch("version")) do |record|
          record.authority_version = method_data.fetch("version")
          record.status = adapter_data.fetch("status") == "active" ? "active" : "scaffold"
          record.method_payload = method_data
        end

        claim_policy = program.country_claim_policies.find_or_create_by!(
          policy_id: manifest.fetch("claim_policy").fetch("profile"),
          version: adapter_data.fetch("version")
        ) do |record|
          record.status = adapter_data.fetch("status") == "active" ? "active" : "scaffold"
          record.policy_payload = manifest.fetch("claim_policy")
        end

        verification_profile = program.country_verification_profiles.find_or_create_by!(
          profile_id: manifest.fetch("verification_profile").fetch("profile"),
          version: adapter_data.fetch("version")
        ) do |record|
          record.status = adapter_data.fetch("status") == "active" ? "active" : "scaffold"
          record.profile_payload = manifest.fetch("verification_profile")
        end

        data_policy = program.country_data_policies.find_or_create_by!(
          policy_id: manifest.fetch("data_policy").fetch("profile"),
          version: adapter_data.fetch("version")
        ) do |record|
          record.status = adapter_data.fetch("status") == "active" ? "active" : "scaffold"
          record.policy_payload = manifest.fetch("data_policy")
        end

        adapter = program.country_adapters.find_or_initialize_by(
          adapter_id: adapter_data.fetch("id"),
          version: adapter_data.fetch("version")
        )
        adapter.assign_attributes(
          country_method_version: method_version,
          country_claim_policy: claim_policy,
          country_verification_profile: verification_profile,
          country_data_policy: data_policy,
          country_code: adapter_data.fetch("country_code"),
          status: adapter_data.fetch("status"),
          manifest: manifest,
          activated_at: Time.current
        )
        adapter.save!

        program.country_institutions.find_or_create_by!(
          name: method_data.fetch("authority"),
          institution_role: "government"
        ) do |record|
          record.status = adapter_data.fetch("status")
        end

        program.country_pilots.find_or_create_by!(name: "#{adapter_data.fetch('country_code')} launch cell") do |record|
          record.status = adapter_data.fetch("status") == "active" ? "active" : "scaffold"
          record.description = "Shared launch-cell projection for #{adapter_data.fetch('id')}."
        end

        program.country_registries.find_or_create_by!(name: "#{adapter_data.fetch('country_code')} registry mapping") do |record|
          record.registry_code = adapter_data.fetch("country_code")
          record.status = "scaffold"
          record.mapping_payload = { adapter_id: adapter_data.fetch("id") }
        end

        adapter
      end

      def default_artifact_profile(profile_id)
        {
          "profile" => { "id" => profile_id, "audience" => "institutional_reliance" },
          "required_receipts" => ["country_compatibility_determination_receipt"],
          "required_documents" => [],
          "verification" => {
            "local_verifier_required" => true,
            "missing_parent_failure" => true,
            "tamper_test_required" => true
          }
        }
      end

      def slug_for_manifest(manifest)
        manifest.fetch("adapter").fetch("country_code").downcase.tr("-", "_")
      end

      def root
        Rails.root.dirname.join("specs/agevidence/country_adapters")
      end
    end
  end
end

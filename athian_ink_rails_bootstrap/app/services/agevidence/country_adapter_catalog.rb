require "yaml"

module Agevidence
  class CountryAdapterCatalog
    REQUIRED_MANIFEST_KEYS = %w[
      adapter global_contract method applicability required_evidence claim_policy
      verification_profile data_policy artifact_profiles limitations
    ].freeze
    VALID_STATUSES = %w[active pilot scaffold research superseded retired].freeze
    IMPLEMENTATION_CLASSIFICATIONS = %w[active pilot scaffold research].freeze

    class << self
      def manifests
        Dir[root.join("*", "adapter.yml")].sort.map do |path|
          manifest = YAML.load_file(path)
          validate_manifest!(manifest)
          manifest.merge("slug" => File.basename(File.dirname(path)), "path" => path.to_s)
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
        report = validation_report(manifest)
        raise KeyError, report.fetch("errors").join(", ") unless report.fetch("errors").empty?

        manifest
      end

      def validation_report(manifest_or_path)
        manifest = manifest_or_path.is_a?(String) || manifest_or_path.respond_to?(:to_path) ? YAML.load_file(manifest_or_path) : manifest_or_path
        errors = []
        REQUIRED_MANIFEST_KEYS.each { |key| errors << "missing required key: #{key}" unless manifest.key?(key) }
        adapter = manifest.fetch("adapter", {})
        method = manifest.fetch("method", {})
        global_contract = manifest.fetch("global_contract", {})

        %w[id version status country_code].each { |key| errors << "missing adapter.#{key}" if adapter[key].blank? }
        %w[id version authority].each { |key| errors << "missing method.#{key}" if method[key].blank? }
        errors << "adapter.status is not supported: #{adapter['status']}" if adapter["status"].present? && !VALID_STATUSES.include?(adapter["status"])
        errors << "global_contract.receipt_envelope must be ink.receipt.v2" unless global_contract["receipt_envelope"] == "ink.receipt.v2"
        errors << "global_contract.agricultural_vocabulary must be athian.agevidence.v1" unless global_contract["agricultural_vocabulary"] == "athian.agevidence.v1"
        errors << "global_contract.verifier_contract must be ink.verify.v1" unless global_contract["verifier_contract"] == "ink.verify.v1"
        errors << "artifact_profiles must not be empty" if Array(manifest["artifact_profiles"]).empty?
        errors << "limitations must not be empty" if Array(manifest["limitations"]).empty?

        {
          "adapter_id" => adapter["id"],
          "country_code" => adapter["country_code"],
          "status" => adapter["status"],
          "classification" => classification_for(adapter["status"], errors),
          "errors" => errors,
          "manifest_path" => manifest["path"].to_s
        }
      rescue Psych::SyntaxError, KeyError, NoMethodError => e
        {
          "adapter_id" => nil,
          "country_code" => nil,
          "status" => nil,
          "classification" => "invalid",
          "errors" => [e.message],
          "manifest_path" => manifest_or_path.to_s
        }
      end

      def resolve_adapter!(value)
        sync! if CountryAdapter.none?
        CountryAdapter.find_by(adapter_id: value) || resolve_country_code!(value)
      end

      private

      def classification_for(status, errors)
        return "invalid" if errors.any?
        return status if IMPLEMENTATION_CLASSIFICATIONS.include?(status)

        "research"
      end

      def resolve_country_code!(value)
        matches = CountryAdapter.where(country_code: value.to_s.upcase).order(:adapter_id, :version)
        active = matches.where(status: "active")
        selected = active.presence || matches
        raise ActiveRecord::RecordNotFound, "Unknown country adapter or country code: #{value}" if selected.empty?
        raise ActiveRecord::RecordNotFound, "Country code #{value} maps to multiple adapters; use adapter id." if selected.size > 1

        selected.first
      end

      def profile_status(status)
        return "retired" if status == "retired"
        return "research" if status == "superseded"
        return status if IMPLEMENTATION_CLASSIFICATIONS.include?(status)

        "scaffold"
      end

      def sync_manifest!(manifest)
        adapter_data = manifest.fetch("adapter")
        method_data = manifest.fetch("method")
        declared_status = adapter_data.fetch("status")
        status = profile_status(declared_status)

        program = CountryProgram.find_or_initialize_by(
          country_code: adapter_data.fetch("country_code"),
          name: method_data.fetch("authority")
        )
        program.assign_attributes(
          program_type: "country_policy_adapter",
          authority_name: method_data.fetch("authority"),
          status: status,
          description: "Data-driven AgEvidence country program projection."
        )
        program.save!

        method = program.country_methods.find_or_initialize_by(method_id: method_data.fetch("id"))
        method.assign_attributes(
          name: method_data.fetch("id").tr("-", " "),
          authority_name: method_data.fetch("authority"),
          status: status
        )
        method.save!

        method_version = method.country_method_versions.find_or_initialize_by(version: method_data.fetch("version"))
        method_version.assign_attributes(
          authority_version: method_data.fetch("version"),
          status: status,
          method_payload: method_data
        )
        method_version.save!

        claim_policy = program.country_claim_policies.find_or_initialize_by(
          policy_id: manifest.fetch("claim_policy").fetch("profile"),
          version: adapter_data.fetch("version")
        )
        claim_policy.assign_attributes(
          status: status,
          policy_payload: manifest.fetch("claim_policy")
        )
        claim_policy.save!

        verification_profile = program.country_verification_profiles.find_or_initialize_by(
          profile_id: manifest.fetch("verification_profile").fetch("profile"),
          version: adapter_data.fetch("version")
        )
        verification_profile.assign_attributes(
          status: status,
          profile_payload: manifest.fetch("verification_profile")
        )
        verification_profile.save!

        data_policy = program.country_data_policies.find_or_initialize_by(
          policy_id: manifest.fetch("data_policy").fetch("profile"),
          version: adapter_data.fetch("version")
        )
        data_policy.assign_attributes(
          status: status,
          policy_payload: manifest.fetch("data_policy")
        )
        data_policy.save!

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
          status: CountryAdapter::STATUSES.include?(declared_status) ? declared_status : status,
          manifest: manifest,
          activated_at: Time.current
        )
        adapter.save!

        institution = program.country_institutions.find_or_initialize_by(
          name: method_data.fetch("authority"),
          institution_role: "government"
        )
        institution.status = status
        institution.save!

        pilot = program.country_pilots.find_or_initialize_by(name: "#{adapter_data.fetch('country_code')} launch cell")
        pilot.assign_attributes(
          status: status == "active" ? "active" : "scaffold",
          description: "Shared launch-cell projection for #{adapter_data.fetch('id')}."
        )
        pilot.save!

        registry = program.country_registries.find_or_initialize_by(name: "#{adapter_data.fetch('country_code')} registry mapping")
        registry.assign_attributes(
          registry_code: adapter_data.fetch("country_code"),
          status: "scaffold",
          mapping_payload: { adapter_id: adapter_data.fetch("id") }
        )
        registry.save!

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

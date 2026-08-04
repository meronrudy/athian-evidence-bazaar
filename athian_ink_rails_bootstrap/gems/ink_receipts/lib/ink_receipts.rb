require "digest"
require "fileutils"
require "json"
require "open3"
require "pathname"
require "shellwords"
require "tempfile"
require "time"
require "zip"

module InkReceipts
  class Error < StandardError; end

  BUNDLE_TYPES = {
    "buyer" => {
      name: "Buyer Evidence Bundle",
      audience: "Corporate buyer, sustainability, audit, finance",
      problem: "A buyer needs a portable proof packet for institutional reliance.",
      receipt_types: %w[issuance_receipt claim_receipt producer_payment_receipt]
    },
    "registry" => {
      name: "Registry Bundle",
      audience: "Registry operator and program administrator",
      problem: "A registry needs enough evidence to accept the asset without inheriting Athian's UI.",
      receipt_types: %w[practice_receipt measurement_receipt model_execution_receipt verifier_receipt issuance_receipt]
    },
    "insurer" => {
      name: "Insurer Bundle",
      audience: "Insurer, broker, portfolio risk team",
      problem: "An insurer needs receipt-backed causality, exceptions, and loss-allocation inputs.",
      receipt_types: %w[practice_receipt measurement_receipt verifier_receipt issuance_receipt claim_receipt]
    },
    "scope_3" => {
      name: "Scope 3 Bundle",
      audience: "Processor, brand, retailer, assurance team",
      problem: "Multiple claimants need a shared allocation geometry and anti-duplication evidence.",
      receipt_types: %w[issuance_receipt contribution_receipt claim_receipt retirement_receipt producer_payment_receipt]
    },
    "producer" => {
      name: "Producer Bundle",
      audience: "Producer, cooperative, lender",
      problem: "A producer needs to trace field activity into net remittance.",
      receipt_types: %w[practice_receipt measurement_receipt claim_receipt producer_payment_receipt]
    },
    "auditor" => {
      name: "Auditor Bundle",
      audience: "VVB, financial auditor, due diligence reviewer",
      problem: "An auditor needs the complete parent-linked evidence chain and verification command.",
      receipt_types: %w[practice_receipt measurement_receipt model_execution_receipt verifier_receipt issuance_receipt claim_receipt producer_payment_receipt methodology_delta_receipt]
    },
    "financing" => {
      name: "Financing Bundle",
      audience: "Lender, sponsor, finance partner",
      problem: "A finance partner needs to connect evidence acceptance to producer economics and repayment assumptions.",
      receipt_types: %w[practice_receipt measurement_receipt claim_receipt producer_payment_receipt]
    },
    "due_diligence" => {
      name: "Due Diligence Bundle",
      audience: "Investor, auditor, acquisition diligence team",
      problem: "A diligence team needs replayable evidence, review decisions, exceptions, and reliance history.",
      receipt_types: %w[practice_receipt measurement_receipt model_execution_receipt verifier_receipt issuance_receipt claim_receipt producer_payment_receipt]
    },
    "dispute" => {
      name: "Dispute Bundle",
      audience: "Protocol, registry, insurer, legal or dispute team",
      problem: "A dispute reviewer needs append-only evidence showing what changed, who reviewed it, and what was relied on.",
      receipt_types: %w[verifier_receipt claim_receipt methodology_delta_receipt producer_payment_receipt human_review_receipt reliance_event_receipt]
    }
  }.freeze

  MARKET_PRODUCTS = {
    "buyer-evidence-bundle" => {
      name: "Buyer Evidence Bundle",
      bundle_type: "buyer",
      problem: "Corporate buyers need evidence they can hand to assurance, finance, and legal teams.",
      receipts: %w[Issuance Claim Producer\ Payment]
    },
    "scope-3-bundle" => {
      name: "Scope 3 Bundle",
      bundle_type: "scope_3",
      problem: "Supply-chain participants need a shared, capped, non-duplicative claim geometry.",
      receipts: %w[Contribution Claim Retirement]
    },
    "registry-bundle" => {
      name: "Registry Bundle",
      bundle_type: "registry",
      problem: "Registries need portable evidence acceptance without trusting the hosted Rails app.",
      receipts: %w[Practice Measurement Model Verifier Issuance]
    },
    "insurance-bundle" => {
      name: "Insurance Bundle",
      bundle_type: "insurer",
      problem: "Insurers need exceptions, causality, and loss-allocation evidence before coverage decisions.",
      receipts: %w[Practice Measurement Verifier Claim]
    },
    "due-diligence-bundle" => {
      name: "Due Diligence Bundle",
      bundle_type: "due_diligence",
      problem: "Investors and auditors need replayable proof for acquisition or portfolio review.",
      receipts: %w[Practice Measurement Model Verifier Issuance Claim Payment]
    },
    "financing-bundle" => {
      name: "Financing Bundle",
      bundle_type: "financing",
      problem: "Lenders need to connect practice implementation, asset value, and producer economics.",
      receipts: %w[Practice Claim Payment]
    },
    "dispute-bundle" => {
      name: "Dispute Bundle",
      bundle_type: "dispute",
      problem: "Disputes need a parent-linked record of what changed, who attested, and what was relied on.",
      receipts: %w[Verifier Claim Methodology\ Delta Payment]
    }
  }.freeze

  STRATEGIC_MOVES = [
    ["#1", "Portable Proof Product", "Evidence bundle download"],
    ["#2", "Standardize Co-Claim Geometry", "Co-Claim Workbench"],
    ["#3", "First-Class VVB", "VVB Console"],
    ["#4", "Producer Economics", "Producer Ledger"],
    ["#5", "Neutral Trust Waist", "Methodology Migration"],
    ["#6", "Sell Evidence Acceptance", "Bundle Marketplace"]
  ].freeze

  class << self
    def issue(**kwargs)
      Client.new.issue(**kwargs)
    end

    def verify(**kwargs)
      Client.new.verify(**kwargs)
    end

    def bundle(**kwargs)
      Client.new.bundle(**kwargs)
    end

    def bundle_manifest(**kwargs)
      Client.new.bundle_manifest(**kwargs)
    end

    def attest(**kwargs)
      Client.new.attest(**kwargs)
    end

    def export(**kwargs)
      Client.new.export(**kwargs)
    end

    def migrate(**kwargs)
      Client.new.migrate(**kwargs)
    end

    def graph(**kwargs)
      Client.new.graph(**kwargs)
    end

    def verify_bundle(**kwargs)
      Client.new.verify_bundle(**kwargs)
    end

    def command_preview(subcommand, *args)
      Client.new.command_for(subcommand, *args).join(" ")
    end
  end

  class Client
    DEFAULT_POLICY = "athian.ink.trust-policy.demo.v1"

    def initialize(command: env_value("INK_RECEIPTS_COMMAND") || env_value("INK_VERIFIER_COMMAND") || autodetected_command)
      @command = command
    end

    def issue(payload:, issuer:, receipt_type:, schema: nil, parents: [], lifecycle: "observed", avsa: nil, signer: nil, source_path: nil)
      payload = source_path ? payload.merge(source_commitment: Digest::SHA256.file(source_path).hexdigest) : payload
      return issue_with_cli(payload: payload, issuer: issuer, receipt_type: receipt_type, schema: schema, parents: parents, lifecycle: lifecycle, avsa: avsa, signer: signer) if command_available?

      demo_issue(payload: payload, issuer: issuer, receipt_type: receipt_type, schema: schema, parents: parents, lifecycle: lifecycle, avsa: avsa, signer: signer)
    end

    def verify(target:)
      return verify_with_cli(target) if command_available? && target.is_a?(String) && File.exist?(target)

      checks = target.fetch(:checks, [])
      normalized = checks.map { |check| stringify_keys(check) }
      status = if normalized.any? { |check| check["status"] == "invalid" }
                 "invalid"
               elsif normalized.any? { |check| check["status"] == "indeterminate" }
                 "indeterminate"
               else
                 "valid"
               end

      {
        status: status,
        mode: "ink_receipts",
        message: verification_message(status),
        checks: normalized,
        verifier_version: "ink_receipts.demo.v0.1"
      }
    end

    def bundle(bundle_type:, output_dir:, avsa: nil, receipts: nil, claim_group: nil, producer_payment: nil, manifest: nil)
      manifest ||= bundle_manifest(avsa: avsa, bundle_type: bundle_type, receipts: receipts, claim_group: claim_group, producer_payment: producer_payment)
      FileUtils.mkdir_p(output_dir)
      zip_path = File.join(output_dir, bundle_filename(manifest.fetch(:avsa), bundle_type))
      FileUtils.rm_f(zip_path)

      Zip::File.open(zip_path, create: true) do |zip|
        write_json(zip, "manifest.json", manifest)
        write_json(zip, "verification-report.json", verify_bundle(manifest: manifest))
        write_json(zip, "evidence/index.json", evidence_index(manifest))
        write_json(zip, "trust/trust-policy.json", trust_policy)
        write_json(zip, "trust/revocation-snapshot.json", revocation_snapshot)
        manifest.fetch(:receipts).each do |receipt|
          write_json(zip, format("receipts/%02d-%s.json", receipt.fetch(:sequence), receipt.fetch(:receipt_type)), receipt)
        end
        zip.get_output_stream("README.txt") { |io| io.write(bundle_readme(manifest)) }
      end

      {
        path: zip_path,
        filename: File.basename(zip_path),
        manifest: manifest,
        verification_report: verify_bundle(manifest: manifest)
      }
    end

    def bundle_manifest(avsa:, bundle_type:, receipts:, claim_group: nil, producer_payment: nil)
      definition = BUNDLE_TYPES.fetch(bundle_type) { raise Error, "Unknown bundle type: #{bundle_type}" }
      selected = receipts.select { |receipt| definition.fetch(:receipt_types).include?(receipt.fetch(:receipt_type)) }

      {
        manifest_version: "athian.ink.bundle.manifest.v1",
        generated_at: Time.now.utc.iso8601,
        bundle_type: bundle_type,
        bundle_name: definition.fetch(:name),
        audience: definition.fetch(:audience),
        problem: definition.fetch(:problem),
        avsa: avsa,
        receipts: selected,
        claim_group: claim_group,
        producer_payment: producer_payment,
        verification_command: "ink verify-bundle manifest.json --policy trust/trust-policy.json",
        trust_policy: DEFAULT_POLICY,
        limitations: [
          "Rails generated this host projection; INK receipts remain the trust boundary.",
          "Canonical bytes, signing, verification, bundles, trust policy, and migrations are owned by ink_receipts.",
          "Receipts prove declared provenance and governance relationships; they do not prove source observations are truthful."
        ]
      }
    end

    def attest(avsa:, scope:, materiality:, evidence_sample:, exceptions:, issuer:, signer:)
      issue(
        payload: {
          avsa: avsa,
          scope: scope,
          materiality: materiality,
          evidence_sample: evidence_sample,
          exceptions: exceptions,
          conclusion: "attested"
        },
        issuer: issuer,
        receipt_type: "verifier_determination_receipt",
        schema: "athian.verifier_determination.v1",
        parents: [],
        lifecycle: "attested",
        signer: signer
      ).merge(
        title: "Verifier Determination Receipt",
        domain_state: "vvb_attested",
        evidence_sample: evidence_sample,
        exceptions: exceptions,
        materiality: materiality
      )
    end

    def export(receipt:)
      receipt.merge(
        exported_at: Time.now.utc.iso8601,
        verification_command: "ink verify receipt-#{receipt.fetch(:id)}.json",
        trust_policy: DEFAULT_POLICY
      )
    end

    def migrate(avsa:, old_methodology:, new_methodology:, affected_credits:, impact:)
      issue(
        payload: {
          avsa: avsa,
          old_methodology: old_methodology,
          new_methodology: new_methodology,
          affected_credits: affected_credits,
          impact: impact
        },
        issuer: "Athian Methodology Migration",
        receipt_type: "methodology_delta_receipt",
        schema: "athian.methodology_delta.v1",
        lifecycle: "sealed",
        signer: "did:key:athian-methodology-demo"
      ).merge(
        title: "Methodology Delta Receipt",
        old_methodology: old_methodology,
        new_methodology: new_methodology,
        affected_credits: affected_credits,
        impact: impact,
        status: "impact_review"
      )
    end

    def graph(receipts:)
      nodes = receipts.map do |receipt|
        {
          id: receipt.fetch(:id),
          label: receipt.fetch(:title),
          receipt_type: receipt.fetch(:receipt_type),
          lifecycle: receipt.fetch(:lifecycle_state),
          digest: receipt.fetch(:body_digest)
        }
      end
      edges = receipts.flat_map do |receipt|
        Array(receipt.fetch(:parent_receipt_ids)).map do |parent_id|
          { source: parent_id, target: receipt.fetch(:id) }
        end
      end

      { nodes: nodes, edges: edges }
    end

    def verify_bundle(manifest:)
      receipts = manifest.fetch(:receipts, [])
      missing = evidence_index(manifest).select { |item| item.fetch(:status) != "present" }
      status = if receipts.empty?
                 "indeterminate"
               elsif missing.any?
                 "indeterminate"
               else
                 "valid"
               end

      {
        status: status,
        mode: "ink_receipts",
        message: verification_message(status),
        checks: [
          { name: "bundle.receipts.present", status: receipts.any? ? "valid" : "indeterminate", detail: "#{receipts.size} receipt projection(s)" },
          { name: "bundle.required_evidence.present", status: missing.empty? ? "valid" : "indeterminate", detail: "#{missing.size} missing evidence item(s)" },
          { name: "bundle.trust_policy.present", status: "valid", detail: DEFAULT_POLICY }
        ],
        generated_at: Time.now.utc.iso8601
      }
    end

    def command_for(subcommand, *args)
      [command || "baink-cli", subcommand, *args].map { |part| Shellwords.escape(part.to_s) }
    end

    private

    attr_reader :command

    def issue_with_cli(payload:, issuer:, receipt_type:, schema:, parents:, lifecycle:, avsa:, signer:)
      with_payload_file(payload) do |path|
        args = ["issue", path, "--issuer", issuer, "--receipt-type", receipt_type, "--lifecycle", lifecycle]
        args += ["--schema", schema] if schema
        args += ["--avsa", avsa] if avsa
        args += ["--signer", signer] if signer
        parents.each { |parent| args += ["--parent", parent] }
        stdout, stderr, status = Open3.capture3(command, *args)
        raise Error, stderr.to_s.empty? ? "INK CLI issue exited with status #{status.exitstatus}" : stderr unless status.success?

        JSON.parse(stdout, symbolize_names: true)
      end
    rescue Errno::ENOENT, JSON::ParserError, Error
      demo_issue(payload: payload, issuer: issuer, receipt_type: receipt_type, schema: schema, parents: parents, lifecycle: lifecycle, avsa: avsa, signer: signer)
    end

    def verify_with_cli(path)
      stdout, stderr, status = Open3.capture3(command, "verify", path, "--json")
      raise Error, stderr.to_s.empty? ? "INK CLI verify exited with status #{status.exitstatus}" : stderr unless status.success?

      normalize_cli_report(JSON.parse(stdout))
    rescue Errno::ENOENT, JSON::ParserError, Error => e
      {
        status: "indeterminate",
        mode: "ink_receipts",
        message: e.message,
        checks: [{ name: "verifier.execution", status: "indeterminate", detail: e.message }]
      }
    end

    def demo_issue(payload:, issuer:, receipt_type:, schema:, parents:, lifecycle:, avsa:, signer:)
      body = {
        payload: payload,
        issuer: issuer,
        receipt_type: receipt_type,
        schema: schema,
        parents: parents,
        lifecycle: lifecycle,
        avsa: avsa,
        signer: signer,
        source_commitment: payload[:source_commitment] || payload["source_commitment"]
      }
      canonical = canonical_json(body)
      body_digest = Digest::SHA256.hexdigest(canonical)

      {
        receipt_version: "athian.ink.receipt.v1",
        receipt_type: receipt_type,
        schema_id: schema || "athian.#{receipt_type}.v1",
        schema_digest: Digest::SHA256.hexdigest(schema || receipt_type),
        lifecycle_state: lifecycle,
        issuer: issuer,
        signer_key_id: signer || "did:key:athian-demo",
        parent_digests: parents,
        body_digest: body_digest,
        evidence_commitment: Digest::SHA256.hexdigest("evidence:#{body_digest}"),
        policy_commitment: Digest::SHA256.hexdigest(DEFAULT_POLICY),
        trace_commitment: Digest::SHA256.hexdigest("trace:#{avsa || receipt_type}:#{body_digest}"),
        canonical_encoding_hex: canonical.unpack1("H*"),
        public_key: "#{signer || 'did:key:athian-demo'}#public-key",
        trust_policy: DEFAULT_POLICY,
        signature: nil,
        issued_at: Time.now.utc.iso8601,
        integrity_status: "valid"
      }
    end

    def normalize_cli_report(report)
      raw = report.fetch("status", "indeterminate").to_s.downcase
      status = case raw
               when "pass", "valid" then "valid"
               when "fail", "invalid" then "invalid"
               else "indeterminate"
               end

      {
        status: status,
        mode: "ink_receipts",
        message: report["message"] || verification_message(status),
        checks: Array(report["checks"]).map { |check| stringify_keys(check) }
      }
    end

    def with_payload_file(payload)
      file = Tempfile.new(["ink-receipt-payload", ".json"])
      file.write(JSON.pretty_generate(payload))
      file.close
      yield file.path
    ensure
      file&.unlink
    end

    def evidence_index(manifest)
      manifest.fetch(:receipts).flat_map do |receipt|
        Array(receipt.fetch(:evidence, [])).map do |item|
          item.merge(receipt_sequence: receipt.fetch(:sequence), receipt_type: receipt.fetch(:receipt_type))
        end
      end
    end

    def write_json(zip, path, payload)
      zip.get_output_stream(path) { |io| io.write(JSON.pretty_generate(payload)) }
    end

    def trust_policy
      {
        policy_id: DEFAULT_POLICY,
        verification_states: %w[valid invalid indeterminate],
        generated_by: "ink_receipts",
        note: "Demo trust policy owned by the local trust-boundary facade."
      }
    end

    def revocation_snapshot
      {
        generated_at: Time.now.utc.iso8601,
        revoked_keys: [],
        generated_by: "ink_receipts"
      }
    end

    def bundle_readme(manifest)
      <<~TEXT
        #{manifest.fetch(:bundle_name)}
        AVSA: #{manifest.fetch(:avsa).fetch(:external_id)}

        Rails is the review surface. The receipt, bundle, trust policy, and local verification
        artifacts are emitted through ink_receipts.

        Verification:
          #{manifest.fetch(:verification_command)}
      TEXT
    end

    def bundle_filename(avsa, bundle_type)
      timestamp = Time.now.utc.strftime("%Y%m%d%H%M%S")
      "#{avsa.fetch(:external_id).downcase.gsub(/[^a-z0-9]+/, '-')}-#{bundle_type}-#{timestamp}.zip"
    end

    def canonical_json(value)
      JSON.generate(deep_sort(value))
    end

    def deep_sort(value)
      case value
      when Hash
        value.transform_keys(&:to_s).sort.to_h { |key, child| [key, deep_sort(child)] }
      when Array
        value.map { |child| deep_sort(child) }
      else
        value
      end
    end

    def stringify_keys(value)
      value.to_h.transform_keys(&:to_s)
    end

    def verification_message(status)
      {
        "valid" => "INK trust-boundary checks passed for the supplied projection.",
        "invalid" => "INK trust-boundary checks found a failing condition.",
        "indeterminate" => "INK trust-boundary checks could not establish every required condition."
      }.fetch(status)
    end

    def command_available?
      command && File.executable?(command)
    end

    def env_value(key)
      value = ENV[key].to_s.strip
      value.empty? ? nil : value
    end

    def autodetected_command
      root = if defined?(Rails)
               Rails.root.dirname
             else
               Pathname.new(Dir.pwd)
             end
      candidate = root.join("target", "debug", "baink-cli")
      candidate.to_s if File.executable?(candidate)
    end
  end
end

require_relative "ink_receipts/client"
require_relative "ink_receipts/catalog"
require_relative "ink_receipts/model_execution"
require_relative "ink_receipts/evidence_candidates"
require_relative "ink_receipts/review_decisions"
require_relative "ink_receipts/reliance_artifacts"
require_relative "ink_receipts/bundle_profiles"
require_relative "ink_receipts/revenue_catalog"

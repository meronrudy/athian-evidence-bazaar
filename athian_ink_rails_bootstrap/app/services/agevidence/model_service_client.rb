require "json"
require "net/http"
require "uri"

module Agevidence
  class ModelServiceClient
    DEFAULT_TASK = "protocol_evidence_extraction"

    def initialize(mode: ENV.fetch("AGEVIDENCE_MODE", "fixture"))
      @mode = mode
    end

    def run_evidence(project:, documents: project.source_documents, task: DEFAULT_TASK, adapter: nil)
      request = request_payload(project: project, documents: documents, task: task, adapter: adapter)
      case mode
      when "fixture"
        fixture_response
      when "local"
        post_json(local_url, request)
      when "remote"
        raise "remote mode requires explicit data-handling configuration" unless ENV["AGEVIDENCE_REMOTE_DATA_HANDLING"] == "explicit"

        post_json(remote_url, request)
      else
        raise "unknown AGEVIDENCE_MODE: #{mode}"
      end
    end

    def request_payload(project:, documents:, task:, adapter: nil)
      {
        adapter_id: adapter&.adapter_id || project.model_runs.last&.model_adapter&.adapter_id || "qwen3.5-4b-reference",
        task: task,
        project: {
          id: "project-#{project.id}",
          claim: project.target_claim
        },
        protocol: {
          code: project.protocol&.code || "ATH-LI-CH4",
          version: project.protocol&.version || "v1"
        },
        country: country_payload(project),
        country_context: project.country_context,
        documents: documents.map do |document|
          {
            document_id: document_value(document, :document_id),
            commitment: document_value(document, :commitment),
            controlled_uri: document_value(document, :controlled_uri)
          }
        end,
        generation: {
          temperature: 0,
          seed: 42
        }
      }
    end

    private

    attr_reader :mode

    def fixture_response
      JSON.parse(File.read(Rails.root.dirname.join("examples/funded_startup/fixture_model_response.json")))
    end

    def local_url
      ENV.fetch("AGEVIDENCE_LOCAL_BASE_URL")
    end

    def remote_url
      ENV.fetch("AGEVIDENCE_REMOTE_BASE_URL")
    end

    def post_json(url, payload)
      uri = URI.join(url, "/v1/evidence-runs")
      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request.body = JSON.generate(payload)
      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
        http.request(request)
      end
      raise "model service returned #{response.code}" unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body)
    end

    def document_value(document, key)
      document.fetch(key) { document.fetch(key.to_s) }
    end

    def country_payload(project)
      country_adapter = project.country_program&.country_adapters&.order(:id)&.first ||
                        project.primary_country_program&.country_adapters&.order(:id)&.first
      return nil unless country_adapter

      {
        country_code: country_adapter.country_code,
        adapter_id: country_adapter.adapter_id,
        adapter_version: country_adapter.version,
        method_id: country_adapter.country_method_version.method_id,
        method_version: country_adapter.country_method_version.version
      }
    end
  end
end

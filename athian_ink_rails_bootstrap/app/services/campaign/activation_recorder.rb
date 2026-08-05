module Campaign
  class ActivationRecorder
    Result = Struct.new(:recorded, :status, :activation_path, :touch, :message, keyword_init: true)

    HEADER_ACCOUNT = "X-AgEvidence-Campaign-Account"
    HEADER_ACTIVATION = "X-AgEvidence-Activation"
    HEADER_REPOSITORY_SHA = "X-AgEvidence-Repository-SHA"
    HEADER_SDK_VERSION = "X-AgEvidence-SDK-Version"

    def self.from_headers(headers)
      new(
        campaign_account_id: headers[HEADER_ACCOUNT].presence,
        activation_id: headers[HEADER_ACTIVATION].presence,
        repository_sha: headers[HEADER_REPOSITORY_SHA].presence,
        sdk_version: headers[HEADER_SDK_VERSION].presence
      )
    end

    def initialize(campaign_account_id: nil, activation_id: nil, repository_sha: nil, sdk_version: nil, cli_version: nil)
      @campaign_account_id = campaign_account_id
      @activation_id = activation_id
      @repository_sha = repository_sha
      @sdk_version = sdk_version
      @cli_version = cli_version
    end

    def record_project_created(project)
      record(
        path_type: "developer_quickstart",
        touch_type: "quickstart_started",
        developer_project: project,
        developer_project_external_id: project.id.to_s,
        metadata: { object_type: "Agevidence::DeveloperProject", object_id: project.id }
      )
    end

    def record_source_record_created(record)
      record(
        path_type: "source_record_api",
        touch_type: "sample_payload_received",
        developer_project: record.developer_project,
        developer_project_external_id: record.developer_project_id.to_s,
        metadata: { object_type: "Agevidence::SourceRecord", object_id: record.id, document_id: record.document_id }
      )
    end

    def record_model_run_created(run)
      record(
        path_type: "developer_quickstart",
        touch_type: "technical_question_received",
        developer_project: run.developer_project,
        developer_project_external_id: run.developer_project_id.to_s,
        metadata: { object_type: "Agevidence::ModelRun", object_id: run.id, evidence_gap_count: run.evidence_gaps.size }
      )
    end

    def record_review_decision_created(decision)
      project = decision.evidence_candidate.model_run.developer_project
      record(
        path_type: "developer_quickstart",
        touch_type: "artifact_review_requested",
        developer_project: project,
        developer_project_external_id: project.id.to_s,
        metadata: { object_type: "Agevidence::ReviewDecision", object_id: decision.id, decision: decision.decision }
      )
    end

    def record_quote_created(quote)
      record(
        path_type: "artifact_verification",
        touch_type: "artifact_review_requested",
        developer_project: quote.developer_project,
        developer_project_external_id: quote.developer_project_id.to_s,
        metadata: { object_type: "Agevidence::PricingQuote", object_id: quote.id, product_code: quote.product_code }
      )
    end

    def record_artifact_order_created(order)
      record(
        path_type: "artifact_verification",
        touch_type: "artifact_review_requested",
        developer_project: order.developer_project,
        developer_project_external_id: order.developer_project_id.to_s,
        metadata: { object_type: "Agevidence::ArtifactOrder", object_id: order.id, product_code: order.product_code, sandbox: true }
      )
    end

    def record_artifact_assembled(order_or_engagement)
      project = order_or_engagement.developer_project
      record(
        path_type: "artifact_verification",
        touch_type: "quickstart_completed",
        status: "completed",
        developer_project: project,
        developer_project_external_id: project.id.to_s,
        metadata: { object_type: order_or_engagement.class.name, object_id: order_or_engagement.id, artifact_generated: true }
      )
    end

    def record_project_4030_replay_completed(source_system: "agevidence_cli")
      record(
        path_type: "cli_project_4030",
        touch_type: "cli_replay_completed",
        source_system: source_system,
        status: "completed",
        metadata: { fixture: "project_4030" }
      )
    end

    def record_integration_event_accepted(event)
      record(
        path_type: "event_inbox",
        touch_type: "sample_payload_received",
        source_system: event.integration_source.key,
        metadata: { object_type: "IntegrationEvent", object_id: event.id, event_type: event.event_type, event_id: event.external_event_id }
      )
    end

    def record(path_type:, touch_type:, source_system: "agevidence_rails", status: "started", developer_project: nil, developer_project_external_id: nil, metadata: {})
      account = find_account
      return ignored("campaign account not supplied") unless campaign_account_id.present?
      return ignored("campaign account not found") unless account

      if mismatched_project?(account, developer_project)
        activation = activation_for(account, path_type, developer_project_external_id)
        activation.update!(status: "ignored", failure_code: "account_project_mismatch", metadata_json: activation.metadata_json.merge(metadata.stringify_keys))
        return Result.new(recorded: false, status: "ignored", activation_path: activation, message: "campaign account does not match developer project")
      end

      activation = activation_for(account, path_type, developer_project_external_id)
      attrs = {
        repository_sha: repository_sha.presence || activation.repository_sha,
        sdk_version: sdk_version.presence || activation.sdk_version,
        cli_version: cli_version.presence || activation.cli_version,
        developer_project_external_id: developer_project_external_id.presence || activation.developer_project_external_id,
        metadata_json: activation.metadata_json.merge(metadata.stringify_keys)
      }
      case status
      when "completed"
        attrs[:status] = "completed"
        attrs[:started_at] = activation.started_at || Time.current
        attrs[:completed_at] = Time.current
      else
        attrs[:status] = activation.status == "completed" ? "completed" : "started"
        attrs[:started_at] = activation.started_at || Time.current
      end
      activation.update!(attrs)

      touch = account.touches.create!(
        touch_type: touch_type,
        source_system: source_system,
        external_reference: activation.external_id,
        repository_sha: repository_sha,
        content_reference: activation.guide_path,
        occurred_at: Time.current,
        metadata_json: metadata.stringify_keys
      )

      Result.new(recorded: true, status: "recorded", activation_path: activation, touch: touch)
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
      Result.new(recorded: false, status: "failed", message: e.message)
    end

    private

    attr_reader :campaign_account_id, :activation_id, :repository_sha, :sdk_version, :cli_version

    def find_account
      Account.find_by(external_id: campaign_account_id)
    end

    def activation_for(account, path_type, developer_project_external_id)
      if activation_id.present?
        existing = Campaign::ActivationPath.find_by(external_id: activation_id)
        if existing && existing.campaign_account_id != account.id
          existing.errors.add(:external_id, "belongs to another campaign account")
          raise ActiveRecord::RecordInvalid.new(existing)
        end
        return existing if existing

        account.activation_paths.create! do |path|
          path.external_id = activation_id
          path.path_type = path_type
          path.status = "invited"
          path.invited_at = Time.current
          path.repository_sha = repository_sha
          path.sdk_version = sdk_version
          path.cli_version = cli_version
          path.developer_project_external_id = developer_project_external_id
        end
      else
        account.activation_paths.where(path_type: path_type, developer_project_external_id: developer_project_external_id).first ||
          account.activation_paths.create!(
            path_type: path_type,
            status: "invited",
            invited_at: Time.current,
            repository_sha: repository_sha,
            sdk_version: sdk_version,
            cli_version: cli_version,
            developer_project_external_id: developer_project_external_id
          )
      end
    end

    def mismatched_project?(account, developer_project)
      developer_project.present? &&
        account.developer_account_id.present? &&
        developer_project.developer_account_id != account.developer_account_id
    end

    def ignored(message)
      Result.new(recorded: false, status: "ignored", message: message)
    end
  end
end

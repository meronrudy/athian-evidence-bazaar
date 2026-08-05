type Json = Record<string, unknown>;

export class AgEvidenceClient {
  constructor(private readonly baseUrl: string) {}

  createProject(input: {
    accountName: string;
    projectName: string;
    targetClaim: string;
  }): Promise<Json> {
    return this.post("/v1/developer/projects", {
      developer_account: {
        name: input.accountName,
        funding_stage: "sandbox",
      },
      project: {
        name: input.projectName,
        project_type: "intervention",
        target_claim: input.targetClaim,
      },
    });
  }

  addSourceRecord(projectId: string, input: {
    documentId: string;
    evidenceType: string;
    controlledUri: string;
    commitment: string;
  }): Promise<Json> {
    return this.post(`/v1/developer/projects/${projectId}/source_records`, {
      source_record: {
        document_id: input.documentId,
        evidence_type: input.evidenceType,
        controlled_uri: input.controlledUri,
        commitment: input.commitment,
        source_system: "developer_sdk",
      },
    });
  }

  createModelRun(projectId: string, adapterId = "qwen3.5-4b-reference"): Promise<Json> {
    return this.post(`/v1/developer/projects/${projectId}/model_runs`, {
      adapter_id: adapterId,
    });
  }

  reviewCandidate(candidateId: number, decision: string, reason: string): Promise<Json> {
    return this.patch(`/v1/developer/candidates/${candidateId}`, {
      review_decision: {
        decision,
        reason,
        reviewer_role: "scientific_reviewer_sandbox",
      },
    });
  }

  createQuote(projectId: string, productCode: string, scope: Json): Promise<Json> {
    return this.post("/v1/pricing/quotes", {
      quote: {
        project_id: projectId,
        product_code: productCode,
        scope,
      },
    });
  }

  createOrder(quoteId: string): Promise<Json> {
    return this.post("/v1/artifact-orders", {
      artifact_order: {
        quote_id: quoteId,
      },
    });
  }

  checkoutOrder(orderId: string): Promise<Json> {
    return this.post(`/v1/artifact-orders/${orderId}/checkout`, {});
  }

  requestArtifact(projectId: string, orderId: string): Promise<Json> {
    return this.post(`/v1/developer/projects/${projectId}/artifacts`, {
      order_id: orderId,
      sandbox_checkout: true,
    });
  }

  retrieveOperation(operationId: string): Promise<Json> {
    return this.get(`/v1/developer/operations/${operationId}`);
  }

  createEvent(envelope: Json, source: string, timestamp: string, signature: string): Promise<Json> {
    return this.post("/v1/integrations/events", envelope, {
      "X-Athian-Integration-Source": source,
      "X-Athian-Timestamp": timestamp,
      "X-Athian-Signature": signature,
    });
  }

  private get(path: string): Promise<Json> {
    return this.request("GET", path);
  }

  private post(path: string, payload: Json, headers: Record<string, string> = {}): Promise<Json> {
    return this.request("POST", path, payload, headers);
  }

  private patch(path: string, payload: Json): Promise<Json> {
    return this.request("PATCH", path, payload);
  }

  private async request(method: string, path: string, payload?: Json, headers: Record<string, string> = {}): Promise<Json> {
    const response = await fetch(`${this.baseUrl}${path}`, {
      method,
      headers: {
        "Content-Type": "application/json",
        ...headers,
      },
      body: payload ? JSON.stringify(payload) : undefined,
    });

    if (!response.ok) {
      throw new Error(`AgEvidence request failed: ${response.status} ${await response.text()}`);
    }

    return response.json();
  }
}

"""Minimal AgEvidence Developer OS client.

This example intentionally mirrors docs/openapi/agevidence.v1.yaml instead of
inventing separate request types. Production SDKs should be generated from the
OpenAPI contract.
"""

from __future__ import annotations

import json
from dataclasses import dataclass
from typing import Any
from urllib import request


@dataclass
class AgEvidenceClient:
    base_url: str

    def create_project(self, account_name: str, project_name: str, target_claim: str) -> dict[str, Any]:
        return self._post(
            "/v1/developer/projects",
            {
                "developer_account": {"name": account_name, "funding_stage": "sandbox"},
                "project": {
                    "name": project_name,
                    "project_type": "intervention",
                    "target_claim": target_claim,
                },
            },
        )

    def add_source_record(
        self,
        project_id: str,
        document_id: str,
        evidence_type: str,
        controlled_uri: str,
        commitment: str,
    ) -> dict[str, Any]:
        return self._post(
            f"/v1/developer/projects/{project_id}/source_records",
            {
                "source_record": {
                    "document_id": document_id,
                    "evidence_type": evidence_type,
                    "controlled_uri": controlled_uri,
                    "commitment": commitment,
                    "source_system": "developer_sdk",
                }
            },
        )

    def create_model_run(self, project_id: str, adapter_id: str = "qwen3.5-4b-reference") -> dict[str, Any]:
        return self._post(
            f"/v1/developer/projects/{project_id}/model_runs",
            {"adapter_id": adapter_id},
        )

    def review_candidate(self, candidate_id: int, decision: str, reason: str) -> dict[str, Any]:
        return self._patch(
            f"/v1/developer/candidates/{candidate_id}",
            {
                "review_decision": {
                    "decision": decision,
                    "reason": reason,
                    "reviewer_role": "scientific_reviewer_sandbox",
                }
            },
        )

    def create_quote(self, project_id: str, product_code: str, scope: dict[str, Any]) -> dict[str, Any]:
        return self._post(
            "/v1/pricing/quotes",
            {"quote": {"project_id": project_id, "product_code": product_code, "scope": scope}},
        )

    def create_order(self, quote_id: str) -> dict[str, Any]:
        return self._post("/v1/artifact-orders", {"artifact_order": {"quote_id": quote_id}})

    def checkout_order(self, order_id: str) -> dict[str, Any]:
        return self._post(f"/v1/artifact-orders/{order_id}/checkout", {})

    def request_artifact(self, project_id: str, order_id: str) -> dict[str, Any]:
        return self._post(
            f"/v1/developer/projects/{project_id}/artifacts",
            {"order_id": order_id, "sandbox_checkout": True},
        )

    def retrieve_operation(self, operation_id: str) -> dict[str, Any]:
        return self._get(f"/v1/developer/operations/{operation_id}")

    def create_event(self, envelope: dict[str, Any], source: str, timestamp: str, signature: str) -> dict[str, Any]:
        return self._post(
            "/v1/integrations/events",
            envelope,
            headers={
                "X-Athian-Integration-Source": source,
                "X-Athian-Timestamp": timestamp,
                "X-Athian-Signature": signature,
            },
        )

    def _get(self, path: str) -> dict[str, Any]:
        req = request.Request(f"{self.base_url}{path}", method="GET")
        return self._send(req)

    def _post(self, path: str, payload: dict[str, Any], headers: dict[str, str] | None = None) -> dict[str, Any]:
        return self._json_request("POST", path, payload, headers=headers)

    def _patch(self, path: str, payload: dict[str, Any]) -> dict[str, Any]:
        return self._json_request("PATCH", path, payload)

    def _json_request(
        self,
        method: str,
        path: str,
        payload: dict[str, Any],
        headers: dict[str, str] | None = None,
    ) -> dict[str, Any]:
        body = json.dumps(payload).encode("utf-8")
        req = request.Request(
            f"{self.base_url}{path}",
            data=body,
            method=method,
            headers={"Content-Type": "application/json", **(headers or {})},
        )
        return self._send(req)

    def _send(self, req: request.Request) -> dict[str, Any]:
        with request.urlopen(req) as response:
            return json.loads(response.read().decode("utf-8"))


if __name__ == "__main__":
    client = AgEvidenceClient("http://localhost:3000")
    project = client.create_project(
        account_name="Northstar Methane Systems Sandbox",
        project_name="Enterprise dairy pilot",
        target_claim="The intervention reduces enteric methane.",
    )
    print(json.dumps(project, indent=2))

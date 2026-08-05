"""Minimal usage example for the canonical AgEvidence Python SDK.

Install from the repository root:

    python3 -m pip install -e "sdks/python[test]"
"""

from __future__ import annotations

import json

from agevidence import Client


if __name__ == "__main__":
    client = Client(base_url="http://localhost:3000")
    project = client.create_project(
        account_name="Northstar Methane Systems Sandbox",
        project_name="Enterprise dairy pilot",
        target_claim="The intervention reduces enteric methane.",
    )
    print(json.dumps(project.model_dump(mode="json", exclude_none=True), indent=2))

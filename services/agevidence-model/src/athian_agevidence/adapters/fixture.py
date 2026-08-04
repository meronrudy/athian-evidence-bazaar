"""Fixture adapter for CI and demos."""

from __future__ import annotations

import json
from importlib import resources

from athian_agevidence.adapters.base import BaseAdapter
from athian_agevidence.contracts import EvidenceRunRequest, EvidenceRunResponse
from athian_agevidence.normalization import normalize_response


class FixtureAdapter(BaseAdapter):
    """Adapter that returns the synthetic Northstar fixture."""

    def run(self, request: EvidenceRunRequest) -> EvidenceRunResponse:
        """Load and normalize the fixture response."""

        with resources.files("athian_agevidence.fixtures").joinpath(
            "northstar_response.json"
        ).open("r", encoding="utf-8") as handle:
            payload = json.load(handle)
        payload["model_run"]["adapter_id"] = request.adapter_id
        return normalize_response(payload)

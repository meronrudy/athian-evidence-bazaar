"""FastAPI entrypoint for the AgEvidence model service."""

from __future__ import annotations

import os

from fastapi import FastAPI

from .adapters.base import BaseAdapter
from .adapters.fixture import FixtureAdapter
from .adapters.openai_compatible import OpenAICompatibleAdapter
from .contracts import EvidenceRunRequest, EvidenceRunResponse


def adapter_for_mode() -> BaseAdapter:
    """Return the configured adapter for the current runtime mode."""

    mode = os.environ.get("AGEVIDENCE_MODE", "fixture")
    if mode == "fixture":
        return FixtureAdapter()
    if mode == "local":
        return OpenAICompatibleAdapter()
    if mode == "remote":
        if os.environ.get("AGEVIDENCE_REMOTE_DATA_HANDLING") != "explicit":
            raise RuntimeError("remote mode requires explicit data-handling configuration")
        return OpenAICompatibleAdapter()
    raise RuntimeError(f"unknown AGEVIDENCE_MODE: {mode}")


app = FastAPI(title="Athian AgEvidence Model Service", version="0.1.0")


@app.post("/v1/evidence-runs", response_model=EvidenceRunResponse)
def create_evidence_run(request: EvidenceRunRequest) -> EvidenceRunResponse:
    """Run evidence extraction and return normalized candidates and gaps."""

    return adapter_for_mode().run(request)

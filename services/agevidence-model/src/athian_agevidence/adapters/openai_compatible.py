"""OpenAI-compatible local endpoint adapter scaffold."""

from __future__ import annotations

import os

from athian_agevidence.adapters.base import BaseAdapter
from athian_agevidence.contracts import EvidenceRunRequest, EvidenceRunResponse


class OpenAICompatibleAdapter(BaseAdapter):
    """Placeholder for local vLLM or SGLang OpenAI-compatible runtimes."""

    def run(self, request: EvidenceRunRequest) -> EvidenceRunResponse:
        """Reject unconfigured local calls in the scaffold."""

        if not os.environ.get("AGEVIDENCE_LOCAL_BASE_URL"):
            raise RuntimeError("AGEVIDENCE_LOCAL_BASE_URL is required for local mode")
        raise NotImplementedError(
            "AGEVIDENCE_TODO: Python owner - local adapter transport is reserved for production completion"
        )

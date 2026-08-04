"""Base adapter interface."""

from __future__ import annotations

from abc import ABC, abstractmethod

from athian_agevidence.contracts import EvidenceRunRequest, EvidenceRunResponse


class BaseAdapter(ABC):
    """Adapter interface for interchangeable model runtimes."""

    @abstractmethod
    def run(self, request: EvidenceRunRequest) -> EvidenceRunResponse:
        """Return a normalized evidence-run response."""

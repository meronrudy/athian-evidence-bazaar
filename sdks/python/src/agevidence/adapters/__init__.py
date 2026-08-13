"""Executable adapter runtime."""

from __future__ import annotations

from agevidence.adapters.base import AdapterEvaluationResult, AdapterMetadata, CountryAdapter
from agevidence.adapters.errors import AdapterAmbiguousError, AdapterError, AdapterNotFoundError, AdapterValidationError
from agevidence.adapters.findings import Finding, FindingCode
from agevidence.adapters.registry import AdapterRegistry, default_registry
from agevidence.adapters.source import Adapter, AdapterFixtureResult, AdapterTestReport, load_source_adapter, test_source_adapter

__all__ = [
    "Adapter",
    "AdapterAmbiguousError",
    "AdapterError",
    "AdapterEvaluationResult",
    "AdapterFixtureResult",
    "AdapterMetadata",
    "AdapterNotFoundError",
    "AdapterRegistry",
    "AdapterTestReport",
    "AdapterValidationError",
    "CountryAdapter",
    "Finding",
    "FindingCode",
    "default_registry",
    "load_source_adapter",
    "test_source_adapter",
]

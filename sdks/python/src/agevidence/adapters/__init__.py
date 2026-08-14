"""Executable adapter runtime."""

from __future__ import annotations

from agevidence.adapters.base import AdapterEvaluationResult, AdapterMetadata, CountryAdapter
from agevidence.adapters.errors import AdapterAmbiguousError, AdapterError, AdapterNotFoundError, AdapterValidationError
from agevidence.adapters.findings import Finding, FindingCode
from agevidence.adapters.registry import AdapterRegistry, default_registry
from agevidence.adapters.source import Adapter, AdapterFixtureResult, AdapterTestReport, load_entry_point_source_adapters, load_source_adapter, test_source_adapter
from agevidence.adapters.tooling import (
    AdapterCompareReport,
    AdapterCoverageReport,
    AdapterScaffoldResult,
    adapter_coverage,
    compare_fixture_sets,
    infer_source_adapter,
    init_source_adapter,
    suggested_mapping_yaml,
)

__all__ = [
    "Adapter",
    "AdapterAmbiguousError",
    "AdapterError",
    "AdapterEvaluationResult",
    "AdapterFixtureResult",
    "AdapterMetadata",
    "AdapterNotFoundError",
    "AdapterRegistry",
    "AdapterCompareReport",
    "AdapterCoverageReport",
    "AdapterScaffoldResult",
    "AdapterTestReport",
    "AdapterValidationError",
    "CountryAdapter",
    "Finding",
    "FindingCode",
    "adapter_coverage",
    "compare_fixture_sets",
    "default_registry",
    "infer_source_adapter",
    "init_source_adapter",
    "load_entry_point_source_adapters",
    "load_source_adapter",
    "suggested_mapping_yaml",
    "test_source_adapter",
]

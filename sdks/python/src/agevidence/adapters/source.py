"""Source-system adapter interface and local conformance testing."""

from __future__ import annotations

import importlib
import importlib.util
import inspect
import json
import sys
from abc import ABC, abstractmethod
from collections.abc import Sequence
from importlib import metadata
from pathlib import Path
from typing import Any, Literal

from pydantic import BaseModel, ConfigDict, Field

from agevidence.adapters.errors import AdapterValidationError
from agevidence.primitives import EvidencePrimitive, local_digest
from agevidence.provenance import ProvenanceReport, check


MappedValue = EvidencePrimitive | dict[str, Any]
AdapterMapResult = MappedValue | Sequence[MappedValue]

KNOWN_PRIMITIVE_TYPES = {
    "SourceRecord",
    "Observation",
    "SpatialObservation",
    "InterventionEvent",
    "OperationalEvent",
    "ModelRun",
}

AUTHORITY_BOUNDARY = (
    "Source adapter tests validate local structure, provenance, deterministic representation, "
    "and canonical primitive compatibility. They do not establish regulatory eligibility, "
    "scientific validity, carbon-credit issuance, external verification, claim ownership, "
    "or institutional reliance."
)


class Adapter(ABC):
    """Experimental source-system mapper.

    Subclass this interface when a source system needs deterministic mapping
    from native JSON records into Agevidence primitives.
    """

    @abstractmethod
    def map(self, record: dict[str, Any]) -> AdapterMapResult:
        """Map one native source record into one or more evidence primitives."""


class AdapterFixtureResult(BaseModel):
    """Per-fixture source adapter test result."""

    model_config = ConfigDict(extra="forbid")

    fixture: str
    mapped: int = 0
    primitive_types: list[str] = Field(default_factory=list)
    local_digests: list[str] = Field(default_factory=list)
    structural_validity: Literal["pass", "fail", "indeterminate"] = "indeterminate"
    provenance: dict[str, int] = Field(default_factory=lambda: {"complete": 0, "partial": 0, "incomplete": 0, "indeterminate": 0})
    failures: list[str] = Field(default_factory=list)
    canonical_schema_extensions_required: bool = False


class AdapterTestReport(BaseModel):
    """Aggregated source adapter conformance report."""

    model_config = ConfigDict(extra="forbid")

    adapter: str
    fixture_count: int
    mapped_count: int
    structurally_valid: int
    provenance_complete: int
    provenance_partial: int
    provenance_incomplete: int
    provenance_indeterminate: int
    failures: list[str] = Field(default_factory=list)
    canonical_schema_extensions_required: bool = False
    no_canonical_schema_extensions_required: bool = True
    fixture_results: list[AdapterFixtureResult] = Field(default_factory=list)
    authority_boundary: str = AUTHORITY_BOUNDARY

    @property
    def passed(self) -> bool:
        """Return whether the adapter passed local conformance."""

        return not self.failures and not self.canonical_schema_extensions_required and self.mapped_count > 0


def test_source_adapter(adapter: str | Adapter, fixtures: str | Path) -> AdapterTestReport:
    """Run source adapter mapping tests over JSON fixture files."""

    adapter_obj = load_source_adapter(adapter) if isinstance(adapter, str) else adapter
    paths = _fixture_paths(Path(fixtures))
    results = [_test_fixture(adapter_obj, path) for path in paths]
    failures = [failure for result in results for failure in result.failures]
    return AdapterTestReport(
        adapter=_adapter_name(adapter_obj),
        fixture_count=len(paths),
        mapped_count=sum(result.mapped for result in results),
        structurally_valid=sum(1 for result in results if result.structural_validity == "pass"),
        provenance_complete=sum(result.provenance.get("complete", 0) for result in results),
        provenance_partial=sum(result.provenance.get("partial", 0) for result in results),
        provenance_incomplete=sum(result.provenance.get("incomplete", 0) for result in results),
        provenance_indeterminate=sum(result.provenance.get("indeterminate", 0) for result in results),
        failures=failures,
        canonical_schema_extensions_required=any(result.canonical_schema_extensions_required for result in results),
        no_canonical_schema_extensions_required=not any(result.canonical_schema_extensions_required for result in results),
        fixture_results=results,
    )


def load_source_adapter(spec: str) -> Adapter:
    """Load a source adapter from `path.py`, `path.py:Object`, or `module:Object`."""

    module_ref, object_name = _split_spec(spec)
    module = _load_module(module_ref)
    target = getattr(module, object_name) if object_name else _select_default_adapter(module)
    return _instantiate_source_adapter(target)


def load_entry_point_source_adapters(group: str = "agevidence.adapters") -> list[Adapter]:
    """Load installed third-party source adapters from Python entry points."""

    adapters: list[Adapter] = []
    for entry_point in metadata.entry_points().select(group=group):
        adapters.append(_instantiate_source_adapter(entry_point.load()))
    return adapters


def _split_spec(spec: str) -> tuple[str, str | None]:
    if ":" in spec:
        module_ref, object_name = spec.split(":", 1)
        if not module_ref or not object_name:
            raise AdapterValidationError("Adapter specs must use path.py:Object or module:Object.", code="ADAPTER_SOURCE_SPEC_INVALID")
        return module_ref, object_name
    if spec.endswith(".py") or Path(spec).suffix == ".py":
        return spec, None
    raise AdapterValidationError("Module adapter specs must use module:Object.", code="ADAPTER_SOURCE_SPEC_INVALID")


def _load_module(module_ref: str):
    path = Path(module_ref)
    if path.suffix == ".py" or path.exists():
        if not path.exists():
            raise AdapterValidationError(f"Adapter file was not found: {module_ref}", code="ADAPTER_SOURCE_FILE_NOT_FOUND")
        module_name = f"agevidence_source_adapter_{abs(hash(path.resolve()))}"
        module_spec = importlib.util.spec_from_file_location(module_name, path)
        if module_spec is None or module_spec.loader is None:
            raise AdapterValidationError(f"Could not load adapter file: {module_ref}", code="ADAPTER_SOURCE_LOAD_FAILED")
        module = importlib.util.module_from_spec(module_spec)
        sys.modules[module_name] = module
        module_spec.loader.exec_module(module)
        return module
    return importlib.import_module(module_ref)


def _select_default_adapter(module: Any) -> Any:
    if hasattr(module, "adapter"):
        return getattr(module, "adapter")
    if hasattr(module, "Adapter"):
        candidate = getattr(module, "Adapter")
        if candidate is not Adapter:
            return candidate

    subclasses = [
        value
        for _, value in inspect.getmembers(module, inspect.isclass)
        if issubclass(value, Adapter) and value is not Adapter and value.__module__ == module.__name__
    ]
    if len(subclasses) == 1:
        return subclasses[0]
    if not subclasses:
        raise AdapterValidationError("No source Adapter subclass found. Use path.py:ObjectName.", code="ADAPTER_SOURCE_NOT_FOUND")
    names = ", ".join(cls.__name__ for cls in subclasses)
    raise AdapterValidationError(f"Multiple source adapters found ({names}). Use path.py:ObjectName.", code="ADAPTER_SOURCE_AMBIGUOUS")


def _instantiate_source_adapter(target: Any) -> Adapter:
    adapter = target() if inspect.isclass(target) else target() if callable(target) and not isinstance(target, Adapter) else target
    if not isinstance(adapter, Adapter):
        raise AdapterValidationError("Source adapter object must be an instance of agevidence.adapters.Adapter.", code="ADAPTER_SOURCE_INVALID")
    return adapter


def _fixture_paths(path: Path) -> list[Path]:
    if path.is_file():
        return [path]
    if path.is_dir():
        paths = sorted(item for item in path.iterdir() if item.suffix == ".json")
        if paths:
            return paths
        raise AdapterValidationError(f"No JSON fixtures found in {path}.", code="ADAPTER_SOURCE_FIXTURES_EMPTY")
    raise AdapterValidationError(f"Fixture path was not found: {path}", code="ADAPTER_SOURCE_FIXTURES_NOT_FOUND")


def _test_fixture(adapter: Adapter, path: Path) -> AdapterFixtureResult:
    result = AdapterFixtureResult(fixture=str(path))
    try:
        record = json.loads(path.read_text(encoding="utf-8"))
        mapped_values = _mapped_values(adapter.map(record))
    except Exception as exc:  # noqa: BLE001 - adapter test reports user adapter failures.
        result.failures.append(f"{path}: {exc}")
        result.structural_validity = "fail"
        return result

    if not mapped_values:
        result.failures.append(f"{path}: adapter returned no primitives")
        result.structural_validity = "fail"
        return result

    reports: list[ProvenanceReport] = []
    for item in mapped_values:
        try:
            payload = item.to_payload() if isinstance(item, EvidencePrimitive) else item
            result.local_digests.append(local_digest(payload))
            report = check(payload)
        except Exception as exc:  # noqa: BLE001 - keep testing remaining fixture outputs.
            result.failures.append(f"{path}: mapped value is not a valid primitive payload: {exc}")
            continue
        result.mapped += 1
        result.primitive_types.append(report.primitive_type)
        result.provenance[report.provenance_completeness] = result.provenance.get(report.provenance_completeness, 0) + 1
        if report.primitive_type not in KNOWN_PRIMITIVE_TYPES:
            result.canonical_schema_extensions_required = True
            result.failures.append(f"{path}: {report.primitive_type} is not a canonical Agevidence primitive")
        if report.structural_validity != "pass":
            missing = ", ".join(finding.code for finding in report.findings if finding.severity == "fail")
            result.failures.append(f"{path}: structural validity failed ({missing or 'unknown failure'})")
        reports.append(report)

    result.structural_validity = "pass" if reports and all(report.structural_validity == "pass" for report in reports) else "fail"
    return result


def _mapped_values(value: AdapterMapResult) -> list[MappedValue]:
    if isinstance(value, EvidencePrimitive):
        return [value]
    if isinstance(value, dict):
        return [value]
    if isinstance(value, Sequence) and not isinstance(value, (str, bytes, bytearray)):
        return list(value)
    raise TypeError("adapter.map must return an EvidencePrimitive, dict, or sequence of those values")


def _adapter_name(adapter: Adapter) -> str:
    return f"{adapter.__class__.__module__}.{adapter.__class__.__name__}"

"""Developer tooling for source-system adapters."""

from __future__ import annotations

import json
from collections.abc import Iterable
from pathlib import Path
from typing import Any

import yaml
from pydantic import BaseModel, ConfigDict, Field, computed_field

from .source import Adapter, load_source_adapter


class AdapterScaffoldResult(BaseModel):
    """Files generated for a local source adapter scaffold."""

    model_config = ConfigDict(extra="forbid")

    name: str
    path: str
    files: dict[str, str]


class AdapterCoverageReport(BaseModel):
    """Field coverage report for a source adapter over native fixtures."""

    model_config = ConfigDict(extra="forbid")

    adapter: str
    fixture_count: int
    source_fields: list[str] = Field(default_factory=list)
    mapped_fields: list[str] = Field(default_factory=list)
    preserved_extension_fields: list[str] = Field(default_factory=list)
    explicitly_ignored_fields: list[str] = Field(default_factory=list)
    silently_lost_fields: list[str] = Field(default_factory=list)

    @computed_field
    @property
    def source_field_count(self) -> int:
        return len(self.source_fields)

    @computed_field
    @property
    def mapped_to_canonical_count(self) -> int:
        return len(self.mapped_fields)

    @computed_field
    @property
    def preserved_as_vendor_extensions_count(self) -> int:
        return len(self.preserved_extension_fields)

    @computed_field
    @property
    def explicitly_ignored_count(self) -> int:
        return len(self.explicitly_ignored_fields)

    @computed_field
    @property
    def silently_lost_count(self) -> int:
        return len(self.silently_lost_fields)

    @computed_field
    @property
    def passed(self) -> bool:
        return not self.silently_lost_fields


class FieldShape(BaseModel):
    """Observed shape of one source field."""

    model_config = ConfigDict(extra="forbid")

    name: str
    types: list[str] = Field(default_factory=list)


class AdapterCompareReport(BaseModel):
    """Comparison between two native fixture sets."""

    model_config = ConfigDict(extra="forbid")

    old: str
    new: str
    new_fields: list[str] = Field(default_factory=list)
    removed_fields: list[str] = Field(default_factory=list)
    changed_fields: dict[str, dict[str, list[str]]] = Field(default_factory=dict)
    evidence_impact: list[str] = Field(default_factory=list)

    @computed_field
    @property
    def breaking(self) -> bool:
        return bool(self.removed_fields or self.changed_fields)


def init_source_adapter(name: str, out: str | Path | None = None) -> AdapterScaffoldResult:
    """Create a reviewable local source adapter scaffold."""

    package_name = _package_name(name)
    target = Path(out) if out else Path(package_name)
    target.mkdir(parents=True, exist_ok=True)
    (target / "fixtures" / "valid").mkdir(parents=True, exist_ok=True)
    (target / "fixtures" / "invalid").mkdir(parents=True, exist_ok=True)
    (target / "tests").mkdir(parents=True, exist_ok=True)
    files = {
        "adapter": target / "adapter.py",
        "manifest": target / "manifest.yaml",
        "readme": target / "README.md",
        "valid_fixture": target / "fixtures" / "valid" / "example.json",
        "invalid_fixture": target / "fixtures" / "invalid" / "missing-required.json",
        "test": target / "tests" / "test_adapter.py",
    }
    _write_if_missing(files["adapter"], _adapter_template(_class_name(name)))
    _write_if_missing(files["manifest"], _manifest_template(name))
    _write_if_missing(files["readme"], f"# {name}\n\nLocal AgEvidence source adapter scaffold.\n")
    _write_if_missing(files["valid_fixture"], json.dumps(_example_record(), indent=2, sort_keys=True) + "\n")
    _write_if_missing(files["invalid_fixture"], json.dumps({"record_id": "missing-required"}, indent=2, sort_keys=True) + "\n")
    _write_if_missing(files["test"], _test_template(_class_name(name)))
    return AdapterScaffoldResult(name=name, path=str(target), files={key: str(path) for key, path in files.items()})


def infer_source_adapter(
    samples: str | Path,
    *,
    out: str | Path | None = None,
    extension_namespace: str | None = None,
    coerce: bool = False,
) -> AdapterScaffoldResult:
    """Generate a reviewable adapter scaffold from representative samples."""

    from agevidence.ingest import ingest_file

    dataset = ingest_file(samples, extension_namespace=extension_namespace, coerce=coerce)
    name = Path(samples).stem if Path(samples).is_file() else Path(samples).name
    scaffold = init_source_adapter(name or "agevidence_adapter", out=out)
    target = Path(scaffold.path)
    summary = _dataset_mapping_summary(dataset)
    (target / "manifest.yaml").write_text(yaml.safe_dump(summary, sort_keys=False), encoding="utf-8")
    (target / "adapter.py").write_text(_inferred_adapter_template(_class_name(name), summary), encoding="utf-8")
    return scaffold


def adapter_coverage(
    adapter: str | Adapter,
    fixtures: str | Path,
    *,
    ignored_fields: Iterable[str] | None = None,
) -> AdapterCoverageReport:
    """Report whether native fields are mapped, preserved, ignored, or lost."""

    adapter_obj = load_source_adapter(adapter) if isinstance(adapter, str) else adapter
    records = _load_fixture_records(fixtures)
    ignored = set(ignored_fields or [])
    source_fields = sorted({field for record in records for field in _source_paths(record)})
    mapped: set[str] = set()
    preserved: set[str] = set()
    explicitly_ignored: set[str] = set()
    lost: set[str] = set()
    for record in records:
        record_fields = set(_source_paths(record))
        caller_ignored = {field for field in record_fields if any(_path_covers(pattern, field) for pattern in ignored)}
        explicitly_ignored.update(caller_ignored)
        classified = set(caller_ignored)
        for output in _mapped_outputs(adapter_obj.map(record)):
            report = _mapping_report_from_output(output)
            if report is None:
                continue
            for item in report.field_coverage:
                field = item.source_field
                if field not in record_fields:
                    continue
                classified.add(field)
                if item.status == "canonical_mapped":
                    mapped.add(field)
                elif item.status == "extension_preserved":
                    preserved.add(field)
                elif item.status == "explicitly_ignored":
                    explicitly_ignored.add(field)
                elif item.status == "silently_lost":
                    lost.add(field)
        lost.update(record_fields - classified)
    return AdapterCoverageReport(
        adapter=f"{adapter_obj.__class__.__module__}.{adapter_obj.__class__.__name__}",
        fixture_count=len(records),
        source_fields=source_fields,
        mapped_fields=sorted(mapped),
        preserved_extension_fields=sorted(preserved),
        explicitly_ignored_fields=sorted(explicitly_ignored),
        silently_lost_fields=sorted(lost - mapped - preserved - explicitly_ignored),
    )


def compare_fixture_sets(old: str | Path, new: str | Path) -> AdapterCompareReport:
    """Compare two source fixture sets by top-level field shape."""

    old_shape = _shape(_load_fixture_records(old))
    new_shape = _shape(_load_fixture_records(new))
    old_fields = set(old_shape)
    new_fields = set(new_shape)
    changed = {
        field: {"old": old_shape[field], "new": new_shape[field]}
        for field in sorted(old_fields & new_fields)
        if old_shape[field] != new_shape[field]
    }
    impact = []
    for field in sorted(set(changed) | (old_fields - new_fields)):
        impact.append(f"{field} may affect mapping or provenance coverage.")
    return AdapterCompareReport(
        old=str(old),
        new=str(new),
        new_fields=sorted(new_fields - old_fields),
        removed_fields=sorted(old_fields - new_fields),
        changed_fields=changed,
        evidence_impact=impact,
    )


def suggested_mapping_yaml(record_or_records: dict[str, Any] | Iterable[dict[str, Any]]) -> str:
    """Render a reviewable mapping YAML suggestion."""

    if isinstance(record_or_records, dict):
        records = [record_or_records]
    else:
        records = list(record_or_records)
    from agevidence.ingest import ingest_many

    summary = _dataset_mapping_summary(ingest_many(records))
    return yaml.safe_dump(summary, sort_keys=False)


def _dataset_mapping_summary(dataset: Any) -> dict[str, Any]:
    primitive_types = dataset.primitive_types
    primitive = max(primitive_types, key=primitive_types.get) if primitive_types else "Unknown"
    reports = [result.mapping for result in dataset.results if result.primitive_type == primitive]
    by_canonical: dict[str, dict[str, Any]] = {}
    for report in reports:
        for field in report.field_mappings:
            if not field.source_field:
                continue
            by_canonical.setdefault(
                field.canonical_field,
                {"from": field.source_field, "confidence": field.confidence},
            )
    return {
        "primitive": primitive,
        "records": dataset.count,
        "confidence": reports[0].confidence if reports else "low",
        "fields": dict(sorted(by_canonical.items())),
        "unmapped_fields": sorted({field for report in reports for field in report.unmapped_fields}),
    }


def _load_fixture_records(fixtures: str | Path) -> list[dict[str, Any]]:
    path = Path(fixtures)
    if path.is_file():
        if path.suffix.lower() in {".csv", ".jsonl", ".ndjson"}:
            from agevidence.ingest import ingest_file

            return [result.native for result in ingest_file(path).results]
        loaded = json.loads(path.read_text(encoding="utf-8"))
        if isinstance(loaded, list):
            return [value for value in loaded if isinstance(value, dict)]
        if isinstance(loaded, dict):
            return [loaded]
        return []
    records: list[dict[str, Any]] = []
    for item in sorted(path.iterdir()):
        if item.suffix != ".json":
            continue
        loaded = json.loads(item.read_text(encoding="utf-8"))
        if isinstance(loaded, list):
            records.extend(value for value in loaded if isinstance(value, dict))
        elif isinstance(loaded, dict):
            records.append(loaded)
    return records


def _shape(records: list[dict[str, Any]]) -> dict[str, list[str]]:
    shape: dict[str, set[str]] = {}
    for record in records:
        for field in _source_paths(record):
            shape.setdefault(field, set()).add(_type_name(_path_value(record, field)))
    return {field: sorted(types) for field, types in sorted(shape.items())}


def _type_name(value: Any) -> str:
    if value is None:
        return "null"
    if isinstance(value, bool):
        return "boolean"
    if isinstance(value, int) and not isinstance(value, bool):
        return "integer"
    if isinstance(value, float):
        return "number"
    if isinstance(value, str):
        return "string"
    if isinstance(value, list):
        return "array"
    if isinstance(value, dict):
        return "object"
    return type(value).__name__


def _mapped_outputs(value: Any) -> list[Any]:
    from agevidence.primitives import EvidencePrimitive

    if isinstance(value, EvidencePrimitive):
        return [value.to_payload()]
    if isinstance(value, dict):
        return [value]
    if hasattr(value, "primitive") and hasattr(value, "mapping"):
        return [value]
    if isinstance(value, Iterable) and not isinstance(value, (str, bytes, bytearray)):
        payloads: list[Any] = []
        for item in value:
            payloads.extend(_mapped_outputs(item))
        return payloads
    return []


def _mapping_report_from_output(output: Any):
    from agevidence.ingest import MappingReport
    from agevidence.primitives import EvidencePrimitive

    if hasattr(output, "mapping"):
        return output.mapping
    payload = output.to_payload() if isinstance(output, EvidencePrimitive) else output
    if not isinstance(payload, dict):
        return None
    metadata = payload.get("metadata")
    if not isinstance(metadata, dict):
        return None
    report = metadata.get("agevidence_mapping")
    if not isinstance(report, dict):
        return None
    return MappingReport.model_validate(report)


def _source_paths(record: dict[str, Any]) -> list[str]:
    from agevidence.ingest.mappings import _source_field_paths

    return _source_field_paths(record)


def _path_covers(pattern: str, path: str) -> bool:
    from agevidence.ingest.mappings import _path_covers as covers

    return covers(pattern, path)


def _path_value(payload: dict[str, Any], path: str) -> Any:
    if "[]" in path:
        head, _, tail = path.partition("[]")
        values = _path_value(payload, head)
        if not isinstance(values, list):
            return None
        child_path = tail.removeprefix(".")
        if not child_path:
            return values
        return [_path_value(item, child_path) for item in values if isinstance(item, dict)]
    current: Any = payload
    for part in path.split("."):
        if not isinstance(current, dict) or part not in current:
            return None
        current = current[part]
    return current


def _preserved_in_metadata(field: str, payload: dict[str, Any]) -> bool:
    metadata = payload.get("metadata")
    if not isinstance(metadata, dict):
        return False
    native = metadata.get("native")
    if isinstance(native, dict) and field in native:
        return True
    extensions = metadata.get("extensions")
    if not isinstance(extensions, dict):
        return False
    return any(isinstance(value, dict) and field in value for value in extensions.values())


def _value_present_in_payload(value: Any, payload: Any, *, skip_metadata: bool = False) -> bool:
    if isinstance(payload, dict):
        for key, item in payload.items():
            if skip_metadata and key == "metadata":
                continue
            if _value_present_in_payload(value, item, skip_metadata=False):
                return True
        return False
    if isinstance(payload, list):
        return any(_value_present_in_payload(value, item, skip_metadata=False) for item in payload)
    return payload == value


def _write_if_missing(path: Path, text: str) -> None:
    if not path.exists():
        path.write_text(text, encoding="utf-8")


def _package_name(name: str) -> str:
    return "".join(char.lower() if char.isalnum() else "_" for char in name).strip("_") or "agevidence_adapter"


def _class_name(name: str) -> str:
    parts = [part for part in re_split_name(name) if part]
    return "".join(part[:1].upper() + part[1:] for part in parts) + "Adapter"


def re_split_name(name: str) -> list[str]:
    return [part for part in _package_name(name).split("_") if part]


def _example_record() -> dict[str, Any]:
    return {
        "animal_id": "animal:example",
        "observable": "liveweight",
        "value": 481.4,
        "unit": "kg",
        "observed_at": "2026-08-12T14:05:11Z",
    }


def _adapter_template(class_name: str) -> str:
    return f'''"""Source adapter scaffold generated by AgEvidence."""

from agevidence.adapters import Adapter
from agevidence import ingest


class {class_name}(Adapter):
    def map(self, record):
        return ingest(record).primitive
'''


def _inferred_adapter_template(class_name: str, summary: dict[str, Any]) -> str:
    primitive = summary.get("primitive", "auto")
    return f'''"""Reviewable source adapter generated from sample payloads."""

from agevidence.adapters import Adapter
from agevidence import ingest


class {class_name}(Adapter):
    primitive = {primitive!r}

    def map(self, record):
        return ingest(record, primitive=self.primitive).primitive
'''


def _manifest_template(name: str) -> str:
    return yaml.safe_dump(
        {
            "id": _package_name(name),
            "name": name,
            "adapter": "adapter.py",
            "status": "scaffold",
            "authority_boundary": "Source adapter output is local evidence mapping, not certification or verification.",
        },
        sort_keys=False,
    )


def _test_template(class_name: str) -> str:
    return f'''from pathlib import Path

from agevidence.adapters import test_source_adapter


def test_adapter_fixtures():
    root = Path(__file__).resolve().parents[1]
    report = test_source_adapter(str(root / "adapter.py") + ":{class_name}", root / "fixtures" / "valid")
    assert report.passed, report.model_dump(mode="json")
'''

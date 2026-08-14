#!/usr/bin/env python3
"""Enforce SDK thin-waist constitution fitness functions."""

from __future__ import annotations

import ast
import filecmp
import json
import re
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
SDK_ROOT = REPO_ROOT / "sdks" / "python" / "src" / "agevidence"
SPEC_SCHEMA_ROOT = REPO_ROOT / "specs" / "agevidence" / "schemas"
PACKAGED_SCHEMA_ROOT = SDK_ROOT / "schemas"

CORE_SCHEMA_STEMS = [
    "asset_state",
    "attachment",
    "calibration_record",
    "derived_observation",
    "external_object",
    "source_record",
    "observation",
    "intervention_event",
    "operational_event",
    "spatial_observation",
    "model_run",
    "product_lot",
    "transformation",
]

LOCAL_BELOW_WAIST = [
    SDK_ROOT / "primitives",
    SDK_ROOT / "provenance",
    SDK_ROOT / "local",
]

FORBIDDEN_IMPORT_PREFIXES = (
    "agevidence.client",
    "agevidence.async_client",
    "agevidence.campaign",
    "agevidence.campaign_cli",
    "agevidence.countries",
    "agevidence.country_cli",
    "agevidence.adapters",
    "agevidence.profiles",
    "agevidence.policies",
)

PROHIBITED_CORE_TOKENS = [
    "ACCU",
    "Verra",
    "Scope3",
    "Scope 3",
    "J-Credit",
    "JCredit",
    "CRCF",
    "DIT",
    "MEQ",
    "Agscent",
    "SeaForest",
    "Sea Forest",
    "Rumin8",
    "Regrow",
    "SwarmFarm",
    "Swarm Farm",
    "Cibo",
    "Cibo Labs",
    "Agronomeye",
    "program_eligibility",
    "accu_eligible",
    "scope3_claim_owner",
    "carbon_credit_id",
]


def main() -> int:
    errors = [
        *check_below_waist_imports(),
        *check_prohibited_core_vocabulary(),
        *check_packaged_schema_mirror(),
    ]
    for line in schema_stability_budget():
        print(line)
    if errors:
        for error in errors:
            print(error)
        return 1
    print("AgEvidence SDK constitution checks passed")
    return 0


def check_below_waist_imports() -> list[str]:
    errors: list[str] = []
    for path in below_waist_python_files():
        tree = ast.parse(path.read_text(encoding="utf-8"), filename=str(path))
        for node in ast.walk(tree):
            module = import_module_name(node)
            if module and module.startswith(FORBIDDEN_IMPORT_PREFIXES):
                errors.append(f"below-waist import violation: {path.relative_to(REPO_ROOT)} imports {module}")
    return errors


def below_waist_python_files() -> list[Path]:
    files: list[Path] = []
    for root in LOCAL_BELOW_WAIST:
        files.extend(path for path in root.glob("**/*.py") if "__pycache__" not in path.parts)
    return sorted(files)


def import_module_name(node: ast.AST) -> str | None:
    if isinstance(node, ast.ImportFrom):
        return node.module
    if isinstance(node, ast.Import):
        for alias in node.names:
            if alias.name.startswith("agevidence."):
                return alias.name
    return None


def check_prohibited_core_vocabulary() -> list[str]:
    errors: list[str] = []
    paths = [*core_schema_paths(), *(SDK_ROOT / "primitives").glob("**/*.py")]
    for path in sorted(paths):
        text = path.read_text(encoding="utf-8", errors="ignore")
        for token in PROHIBITED_CORE_TOKENS:
            if prohibited_token_present(text, token):
                errors.append(f"prohibited core vocabulary {token!r} in {path.relative_to(REPO_ROOT)}")
    return errors


def prohibited_token_present(text: str, token: str) -> bool:
    if token.replace("_", "").replace("-", "").replace(" ", "").isalnum():
        return re.search(rf"(?<![A-Za-z0-9_]){re.escape(token)}(?![A-Za-z0-9_])", text, re.IGNORECASE) is not None
    return re.search(re.escape(token), text, re.IGNORECASE) is not None


def check_packaged_schema_mirror() -> list[str]:
    errors: list[str] = []
    for spec_path in core_schema_paths():
        packaged_path = PACKAGED_SCHEMA_ROOT / spec_path.name
        if not packaged_path.is_file():
            errors.append(f"packaged schema missing: {packaged_path.relative_to(REPO_ROOT)}")
        elif not filecmp.cmp(spec_path, packaged_path, shallow=False):
            errors.append(f"packaged schema drift: {packaged_path.relative_to(REPO_ROOT)} != {spec_path.relative_to(REPO_ROOT)}")
    return errors


def core_schema_paths() -> list[Path]:
    return [SPEC_SCHEMA_ROOT / f"athian.agevidence.{stem}.v1.json" for stem in CORE_SCHEMA_STEMS]


def schema_stability_budget() -> list[str]:
    field_count = 0
    for path in core_schema_paths():
        schema = json.loads(path.read_text(encoding="utf-8"))
        field_count += len(schema.get("properties", {}))
    extension_count = len(list((SDK_ROOT / "adapters").glob("**/*.py")))
    profile_mapping_count = len(list((REPO_ROOT / "specs" / "agevidence" / "country_adapters").glob("**/*.yml")))
    return [
        "Schema stability budget:",
        f"  core_primitives: {len(CORE_SCHEMA_STEMS)}",
        f"  core_fields: {field_count}",
        f"  extension_modules: {extension_count}",
        f"  profile_mapping_files: {profile_mapping_count}",
    ]


if __name__ == "__main__":
    raise SystemExit(main())

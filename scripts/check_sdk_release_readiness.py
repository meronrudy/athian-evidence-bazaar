#!/usr/bin/env python3
"""Check Agevidence Python SDK release readiness."""

from __future__ import annotations

import re
import sys
import tomllib
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
SDK_ROOT = REPO_ROOT / "sdks" / "python"
PYPROJECT = SDK_ROOT / "pyproject.toml"
PACKAGE_ROOT = SDK_ROOT / "src" / "agevidence"
RELEASE_WORKFLOW = REPO_ROOT / ".github" / "workflows" / "sdk-python-release.yml"
SDK_DOCS = SDK_ROOT / "docs"

REQUIRED_GOLDEN_FIXTURES = {
    "demo_bundle.json",
    "observation_liveweight_v1.json",
    "observation_methane_v1.json",
    "intervention_feed_additive_v1.json",
    "model_run_spatial_v1.json",
    "model_run_neutral_v1.json",
    "operational_event_spot_spray_v1.json",
    "observation_missing_unit.json",
    "observation_missing_timestamp.json",
    "model_run_missing_version.json",
    "model_run_neutral_missing_version.json",
    "intervention_missing_target.json",
}

REQUIRED_LOCAL_FIXTURES = {
    "livestock-weight.json",
    "methane-observation.json",
    "intervention-dose.json",
    "spatial-model.json",
    "machine-operation.json",
}

FORBIDDEN_BRANDING = {
    "mech-lab",
    "mech_lab",
    "mech lab",
    "athian-agevidence-model",
}


def main() -> int:
    errors: list[str] = []
    project = _project_metadata()
    errors.extend(_check_version(project))
    errors.extend(_check_metadata(project))
    errors.extend(_check_packaged_files())
    errors.extend(_check_release_workflow())
    errors.extend(_check_public_exports_and_cli())
    errors.extend(_check_docs_links())
    errors.extend(_check_local_first_constraints())
    errors.extend(_check_verifier_contract())
    errors.extend(_check_fixtures())

    if errors:
        for error in errors:
            print(error)
        return 1
    print("Agevidence Python SDK release readiness passed")
    return 0


def _project_metadata() -> dict:
    return tomllib.loads(PYPROJECT.read_text(encoding="utf-8"))["project"]


def _check_version(project: dict) -> list[str]:
    sys.path.insert(0, str(SDK_ROOT / "src"))
    import agevidence

    if project["version"] != agevidence.__version__:
        return [f"pyproject version {project['version']} != agevidence.__version__ {agevidence.__version__}"]
    return []


def _check_metadata(project: dict) -> list[str]:
    errors = []
    if project.get("name") != "agevidence":
        errors.append("project name must be agevidence")
    if project.get("readme", {}).get("file") != "docs/pypi.md":
        errors.append("PyPI readme must be docs/pypi.md")
    if project.get("requires-python") != ">=3.11":
        errors.append("requires-python must be >=3.11")
    scripts = tomllib.loads(PYPROJECT.read_text(encoding="utf-8")).get("project", {})
    text = PYPROJECT.read_text(encoding="utf-8").lower()
    for forbidden in FORBIDDEN_BRANDING:
        if forbidden in text:
            errors.append(f"obsolete package branding in pyproject: {forbidden}")
    if "agevidence.cli:app" not in PYPROJECT.read_text(encoding="utf-8"):
        errors.append("CLI entry point must remain agevidence.cli:app")
    required_keys = {"keywords", "classifiers", "urls"}
    missing = required_keys - set(project)
    for key in sorted(missing):
        errors.append(f"missing project metadata: {key}")
    classifiers = set(project.get("classifiers", []))
    if "Development Status :: 5 - Production/Stable" not in classifiers:
        errors.append("v1 release metadata must use Production/Stable classifier")
    if "Development Status :: 3 - Alpha" in classifiers:
        errors.append("v1 release metadata must not use Alpha classifier")
    return errors


def _check_packaged_files() -> list[str]:
    errors = []
    if not (PACKAGE_ROOT / "py.typed").is_file():
        errors.append("py.typed missing")
    if not (SDK_ROOT / "docs" / "pypi.md").is_file():
        errors.append("docs/pypi.md missing")
    package_data = tomllib.loads(PYPROJECT.read_text(encoding="utf-8")).get("tool", {}).get("setuptools", {}).get("package-data", {})
    agevidence_data = package_data.get("agevidence", [])
    for pattern in ("py.typed", "fixtures/data/*.json", "schemas/*.json"):
        if pattern not in agevidence_data:
            errors.append(f"package data missing {pattern}")
    find_config = tomllib.loads(PYPROJECT.read_text(encoding="utf-8")).get("tool", {}).get("setuptools", {}).get("packages", {}).get("find", {})
    if find_config.get("where") != ["src"] or find_config.get("include") != ["agevidence*"]:
        errors.append("package discovery must be limited to agevidence* under src")
    return errors


def _check_release_workflow() -> list[str]:
    if not RELEASE_WORKFLOW.is_file():
        return ["release workflow missing"]
    text = RELEASE_WORKFLOW.read_text(encoding="utf-8")
    errors = []
    required = [
        "sdk-python-v*",
        "id-token: write",
        "environment:",
        "name: pypi",
        "pypa/gh-action-pypi-publish@release/v1",
        "working-directory: sdks/python",
        "python -m build",
        "python -m twine check dist/*",
    ]
    for value in required:
        if value not in text:
            errors.append(f"release workflow missing {value}")
    if "password:" in text or "api-token" in text.lower():
        errors.append("release workflow must not use long-lived PyPI API tokens")
    return errors


def _check_public_exports_and_cli() -> list[str]:
    errors = []
    sys.path.insert(0, str(SDK_ROOT / "src"))
    try:
        from typer.testing import CliRunner

        from agevidence.adapters import Adapter, AdapterTestReport, load_source_adapter, test_source_adapter
        from agevidence.cli import app
    except Exception as exc:  # noqa: BLE001 - readiness reports import failures.
        return [f"source adapter public exports or CLI failed to import: {exc}"]

    expected_exports = {
        "Adapter": Adapter,
        "AdapterTestReport": AdapterTestReport,
        "load_source_adapter": load_source_adapter,
        "test_source_adapter": test_source_adapter,
    }
    for name, value in expected_exports.items():
        if value is None:
            errors.append(f"missing source adapter export: {name}")

    runner = CliRunner()
    for command in (["adapter", "--help"], ["adapter", "test", "--help"], ["ingest", "--help"], ["explain", "--help"]):
        result = runner.invoke(app, command)
        if result.exit_code != 0:
            errors.append(f"CLI command failed readiness check: agevidence {' '.join(command)}")
    return errors


def _check_docs_links() -> list[str]:
    errors = []
    for path in sorted(SDK_DOCS.rglob("*.md")):
        text = _strip_fenced_code(path.read_text(encoding="utf-8"))
        for target in re.findall(r"!?\[[^\]]*\]\(([^)]+)\)", text):
            if not target or _is_external_link(target):
                continue
            clean = target.strip()
            if clean.startswith("<") and clean.endswith(">"):
                clean = clean[1:-1]
            clean = clean.split("#", 1)[0]
            if not clean:
                continue
            resolved = (path.parent / clean).resolve()
            try:
                resolved.relative_to(REPO_ROOT.resolve())
            except ValueError:
                errors.append(f"{path.relative_to(REPO_ROOT)} links outside repo: {target}")
                continue
            if not resolved.exists():
                errors.append(f"{path.relative_to(REPO_ROOT)} has broken link: {target}")
    return errors


def _strip_fenced_code(text: str) -> str:
    return re.sub(r"```.*?```", "", text, flags=re.DOTALL)


def _is_external_link(target: str) -> bool:
    return target.startswith(("http://", "https://", "mailto:", "#"))


def _check_local_first_constraints() -> list[str]:
    errors = []
    for relative in ("demo.py", "fixtures/generator.py", "provenance/checks.py", "ingest/infer.py"):
        text = (PACKAGE_ROOT / relative).read_text(encoding="utf-8")
        if "AGEVIDENCE_BASE_URL" in text:
            errors.append(f"{relative} must not require AGEVIDENCE_BASE_URL")
        if "AGEVIDENCE_API_TOKEN" in text:
            errors.append(f"{relative} must not require AGEVIDENCE_API_TOKEN")
    return errors


def _check_verifier_contract() -> list[str]:
    text = (PACKAGE_ROOT / "verification.py").read_text(encoding="utf-8")
    errors = []
    if "verify-bundle" in text:
        errors.append("Python verifier still references verify-bundle")
    if '"verify"' not in text or '"--json"' not in text:
        errors.append("Python verifier must call baink-cli verify BUNDLE --json")
    return errors


def _check_fixtures() -> list[str]:
    errors = []
    golden_root = SDK_ROOT / "tests" / "fixtures" / "golden"
    missing_golden = sorted(name for name in REQUIRED_GOLDEN_FIXTURES if not (golden_root / name).is_file())
    for name in missing_golden:
        errors.append(f"required golden fixture missing: {name}")
    fixture_root = PACKAGE_ROOT / "fixtures" / "data"
    missing_local = sorted(name for name in REQUIRED_LOCAL_FIXTURES if not (fixture_root / name).is_file())
    for name in missing_local:
        errors.append(f"required local fixture missing: {name}")
    return errors


if __name__ == "__main__":
    raise SystemExit(main())

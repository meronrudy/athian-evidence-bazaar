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
SDK_README = SDK_ROOT / "README.md"
PYPI_README = SDK_ROOT / "docs" / "pypi.md"
RELEASE_WORKFLOW = REPO_ROOT / ".github" / "workflows" / "sdk-python-release.yml"
CI_WORKFLOW = REPO_ROOT / ".github" / "workflows" / "sdk-python-ci.yml"
SDK_DOCS = SDK_ROOT / "docs"
V1_RELEASE_NOTES = REPO_ROOT / "docs" / "releases" / "v1.0.0" / "RELEASE_NOTES.md"
V1_POST_PUBLISH_CHECKLIST = REPO_ROOT / "docs" / "releases" / "v1.0.0" / "POST_PUBLISH_CHECKLIST.md"

EXPECTED_VERSION = "1.0.0"
EXPECTED_TAG = "sdk-python-v1.0.0"

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

REQUIRED_SCHEMA_FILES = {
    "athian.agevidence.asset_state.v1.json",
    "athian.agevidence.attachment.v1.json",
    "athian.agevidence.calibration_record.v1.json",
    "athian.agevidence.derived_observation.v1.json",
    "athian.agevidence.external_object.v1.json",
    "athian.agevidence.source_record.v1.json",
    "athian.agevidence.observation.v1.json",
    "athian.agevidence.spatial_observation.v1.json",
    "athian.agevidence.intervention_event.v1.json",
    "athian.agevidence.operational_event.v1.json",
    "athian.agevidence.model_run.v1.json",
    "athian.agevidence.product_lot.v1.json",
    "athian.agevidence.transformation.v1.json",
}

COMPATIBILITY_MANIFEST = REPO_ROOT / "specs" / "agevidence" / "compatibility-manifest.json"
PACKAGED_COMPATIBILITY_MANIFEST = PACKAGE_ROOT / "resources" / "compatibility-manifest.json"
DOCS_COMPATIBILITY_MANIFEST = SDK_DOCS / "reference" / "compatibility-manifest.json"

FORBIDDEN_BRANDING = {
    "mech-lab",
    "mech_lab",
    "mech lab",
    "athian-agevidence-model",
}

FORBIDDEN_RELEASE_FACING_TERMS = {
    "0.2.0a1",
    "1.0.0rc",
    "Development Status :: 3 - Alpha",
}

AUTHORITY_BOUNDARY_TERMS = {
    "regulatory eligibility",
    "scientific validity",
    "carbon-credit issuance",
    "third-party verification",
    "claim ownership",
    "institutional reliance",
}

TRUST_BOUNDARY_TERMS = {
    "receipt",
    "dCBOR",
    "bundle verification",
}

RELEASE_FACING_FILES = {
    "SDK README": SDK_README,
    "PyPI README": PYPI_README,
    "v1 release notes": V1_RELEASE_NOTES,
    "release workflow": RELEASE_WORKFLOW,
    "SDK CI workflow": CI_WORKFLOW,
}


def main() -> int:
    errors: list[str] = []
    project = _project_metadata()
    errors.extend(_check_version(project))
    errors.extend(_check_metadata(project))
    errors.extend(_check_packaged_files())
    errors.extend(_check_packaged_schemas())
    errors.extend(_check_compatibility_manifest_sync())
    errors.extend(_check_optional_extras())
    errors.extend(_check_release_workflow())
    errors.extend(_check_public_exports_and_cli())
    errors.extend(_check_docs_links())
    errors.extend(_check_release_docs())
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

    errors = []
    if project["version"] != EXPECTED_VERSION:
        errors.append(f"pyproject version must be {EXPECTED_VERSION} for v1 release readiness")
    if agevidence.__version__ != EXPECTED_VERSION:
        errors.append(f"agevidence.__version__ must be {EXPECTED_VERSION} for v1 release readiness")
    if project["version"] != agevidence.__version__:
        errors.append(f"pyproject version {project['version']} != agevidence.__version__ {agevidence.__version__}")
    return errors


def _check_metadata(project: dict) -> list[str]:
    errors = []
    if project.get("name") != "agevidence":
        errors.append("project name must be agevidence")
    if project.get("readme", {}).get("file") != "docs/pypi.md":
        errors.append("PyPI readme must be docs/pypi.md")
    if project.get("requires-python") != ">=3.11":
        errors.append("requires-python must be >=3.11")
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
    if not PYPI_README.is_file():
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


def _check_packaged_schemas() -> list[str]:
    errors = []
    spec_root = REPO_ROOT / "specs" / "agevidence" / "schemas"
    package_schema_root = PACKAGE_ROOT / "schemas"
    for name in sorted(REQUIRED_SCHEMA_FILES):
        spec_path = spec_root / name
        package_path = package_schema_root / name
        if not spec_path.is_file():
            errors.append(f"canonical schema missing: {spec_path.relative_to(REPO_ROOT)}")
            continue
        if not package_path.is_file():
            errors.append(f"packaged schema missing: {package_path.relative_to(REPO_ROOT)}")
            continue
        if spec_path.read_text(encoding="utf-8") != package_path.read_text(encoding="utf-8"):
            errors.append(f"packaged schema differs from canonical spec: {name}")
    return errors


def _check_compatibility_manifest_sync() -> list[str]:
    errors = []
    copies = {
        "canonical compatibility manifest": COMPATIBILITY_MANIFEST,
        "packaged compatibility manifest": PACKAGED_COMPATIBILITY_MANIFEST,
        "docs compatibility manifest": DOCS_COMPATIBILITY_MANIFEST,
    }
    for label, path in copies.items():
        if not path.is_file():
            errors.append(f"{label} missing: {path.relative_to(REPO_ROOT)}")
    if errors:
        return errors
    canonical = COMPATIBILITY_MANIFEST.read_text(encoding="utf-8")
    for label, path in copies.items():
        if path == COMPATIBILITY_MANIFEST:
            continue
        if path.read_text(encoding="utf-8") != canonical:
            errors.append(f"{label} differs from canonical compatibility manifest")
    return errors


def _check_optional_extras() -> list[str]:
    project = _project_metadata()
    optional = project.get("optional-dependencies", {})
    errors = []
    required_modules = {
        "geo": PACKAGE_ROOT / "geo.py",
        "otel": PACKAGE_ROOT / "otel.py",
        "pytest": PACKAGE_ROOT / "pytest_plugin.py",
        "viz": PACKAGE_ROOT / "viz.py",
    }
    for extra, module_path in required_modules.items():
        if extra not in optional:
            errors.append(f"optional extra missing from package metadata: {extra}")
        if not module_path.is_file():
            errors.append(f"optional extra module missing: {module_path.relative_to(REPO_ROOT)}")
    entry_points = tomllib.loads(PYPROJECT.read_text(encoding="utf-8")).get("project", {}).get("entry-points", {})
    pytest_plugins = entry_points.get("pytest11", {})
    if pytest_plugins.get("agevidence") != "agevidence.pytest_plugin":
        errors.append("pytest optional extra must expose agevidence.pytest_plugin through pytest11 entry points")
    return errors


def _check_release_workflow() -> list[str]:
    if not RELEASE_WORKFLOW.is_file():
        return ["release workflow missing"]
    text = RELEASE_WORKFLOW.read_text(encoding="utf-8")
    errors = []
    required = [
        EXPECTED_TAG,
        "id-token: write",
        "environment:",
        "name: pypi",
        "pypa/gh-action-pypi-publish@release/v1",
        "actions/upload-artifact@v4",
        "softprops/action-gh-release@v2",
        "draft: true",
        "working-directory: sdks/python",
        "python -m build",
        "python -m twine check dist/*",
        "bash scripts/agevidence_check_all.sh",
        "Fresh venv wheel smoke test",
        "Fresh venv sdist smoke test",
    ]
    for value in required:
        if value not in text:
            errors.append(f"release workflow missing {value}")
    if "password:" in text or "api-token" in text.lower():
        errors.append("release workflow must not use long-lived PyPI API tokens")
    trigger_section = text.split("jobs:", 1)[0]
    if "sdk-python-v*" in trigger_section:
        errors.append(f"release workflow trigger must be pinned to {EXPECTED_TAG}, not sdk-python-v*")
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


def _check_release_docs() -> list[str]:
    errors = []
    for label, path in RELEASE_FACING_FILES.items():
        if not path.is_file():
            errors.append(f"{label} missing: {path.relative_to(REPO_ROOT)}")
            continue
        text = path.read_text(encoding="utf-8")
        for term in FORBIDDEN_RELEASE_FACING_TERMS:
            if term in text:
                errors.append(f"{label} contains stale non-v1 release reference: {term}")

    authority_docs = {
        "SDK README": SDK_README,
        "PyPI README": PYPI_README,
        "v1 release notes": V1_RELEASE_NOTES,
    }
    for label, path in authority_docs.items():
        if path.is_file():
            _require_terms(errors, label, path, AUTHORITY_BOUNDARY_TERMS, "authority-boundary")

    trust_docs = {
        "SDK README": SDK_README,
        "PyPI README": PYPI_README,
        "v1 release notes": V1_RELEASE_NOTES,
    }
    for label, path in trust_docs.items():
        if not path.is_file():
            continue
        _require_terms(errors, label, path, TRUST_BOUNDARY_TERMS, "trust-boundary")
        text = path.read_text(encoding="utf-8")
        if "Rust trust boundary" not in text and "Rust verifier" not in text:
            errors.append(f"{label} missing Rust trust-boundary delegation language")

    if V1_RELEASE_NOTES.is_file():
        notes = V1_RELEASE_NOTES.read_text(encoding="utf-8")
        for value in ("Known Limitations", "SHA-256", EXPECTED_TAG, "python3 -m pytest sdks/python"):
            if value not in notes:
                errors.append(f"v1 release notes missing {value}")

    if V1_POST_PUBLISH_CHECKLIST.is_file():
        checklist = V1_POST_PUBLISH_CHECKLIST.read_text(encoding="utf-8")
        required = [
            f"python -m pip install agevidence=={EXPECTED_VERSION}",
            "agevidence adapter test",
            "SHA-256",
            "do not replace files",
            f"yank `{EXPECTED_VERSION}`",
        ]
        for value in required:
            if value not in checklist:
                errors.append(f"v1 post-publish checklist missing {value}")
    else:
        errors.append("v1 post-publish checklist missing")
    return errors


def _require_terms(errors: list[str], label: str, path: Path, terms: set[str], context: str) -> None:
    text = _normalized_text(path.read_text(encoding="utf-8"))
    missing = sorted(term for term in terms if _normalized_text(term) not in text)
    if missing:
        errors.append(f"{label} missing {context} terms: {', '.join(missing)}")


def _normalized_text(text: str) -> str:
    return re.sub(r"\s+", " ", text).lower()


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

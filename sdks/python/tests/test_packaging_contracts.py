from __future__ import annotations

import re
import tomllib
from pathlib import Path

from setuptools import find_packages


SDK_ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = SDK_ROOT.parents[1]
PYPROJECT = SDK_ROOT / "pyproject.toml"
PACKAGE_ROOT = SDK_ROOT / "src" / "agevidence"

REQUIRED_SCHEMA_FILES = {
    "athian.agevidence.source_record.v1.json",
    "athian.agevidence.observation.v1.json",
    "athian.agevidence.spatial_observation.v1.json",
    "athian.agevidence.intervention_event.v1.json",
    "athian.agevidence.operational_event.v1.json",
    "athian.agevidence.model_run.v1.json",
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


def project_metadata():
    return tomllib.loads(PYPROJECT.read_text(encoding="utf-8"))


def normalized_text(text: str) -> str:
    return re.sub(r"\s+", " ", text).lower()


def test_public_package_contract():
    data = project_metadata()
    project = data["project"]

    assert project["name"] == "agevidence"
    assert project["version"] == "1.0.0"
    assert data["project"]["scripts"]["agevidence"] == "agevidence.cli:app"
    assert project["requires-python"] == ">=3.11"
    assert project["readme"]["file"] == "docs/pypi.md"
    assert project["description"] == "Portable evidence primitives and verification tooling for agricultural software"


def test_release_metadata_is_pypi_ready():
    project = project_metadata()["project"]

    assert "Typing :: Typed" in project["classifiers"]
    assert "Development Status :: 5 - Production/Stable" in project["classifiers"]
    assert "Development Status :: 3 - Alpha" not in project["classifiers"]
    assert set(["agtech", "agriculture", "evidence", "provenance", "verification", "mrv"]).issubset(project["keywords"])
    assert project["urls"]["Repository"] == "https://github.com/meronrudy/athian-evidence-bazaar"
    assert project["urls"]["Documentation"].endswith("/tree/main/sdks/python")


def test_package_discovery_is_scoped_to_agevidence():
    data = project_metadata()
    find_config = data["tool"]["setuptools"]["packages"]["find"]
    packages = find_packages(where=str(SDK_ROOT / "src"))

    assert find_config["where"] == ["src"]
    assert find_config["include"] == ["agevidence*"]
    assert "agevidence" in packages
    assert all(package == "agevidence" or package.startswith("agevidence.") for package in packages)


def test_packaged_resources_contract():
    data = project_metadata()
    package_data = data["tool"]["setuptools"]["package-data"]["agevidence"]

    assert "py.typed" in package_data
    assert "resources/*.json" in package_data
    assert "fixtures/data/*.json" in package_data
    assert "schemas/*.json" in package_data
    assert "proofkits/*.json" in package_data
    assert "proofkits/fixtures/*.json" in package_data
    assert "proofkits/expected/*.json" in package_data
    assert "proofkits/readmes/*.md" in package_data
    assert (PACKAGE_ROOT / "py.typed").exists()
    assert (SDK_ROOT / "docs" / "pypi.md").exists()


def test_packaged_primitive_schemas_match_canonical_specs():
    spec_root = REPO_ROOT / "specs" / "agevidence" / "schemas"
    packaged_root = PACKAGE_ROOT / "schemas"

    for name in REQUIRED_SCHEMA_FILES:
        assert (packaged_root / name).exists()
        assert (packaged_root / name).read_text(encoding="utf-8") == (spec_root / name).read_text(encoding="utf-8")


def test_local_functionality_does_not_import_rails_client_layer():
    local_modules = [
        SDK_ROOT / "src" / "agevidence" / "demo.py",
        SDK_ROOT / "src" / "agevidence" / "ingest" / "infer.py",
        SDK_ROOT / "src" / "agevidence" / "provenance" / "checks.py",
    ]

    for path in local_modules:
        source = path.read_text(encoding="utf-8")
        assert "from .client" not in source
        assert "from agevidence.client" not in source
        assert "AGEVIDENCE_BASE_URL" not in source
        assert "AGEVIDENCE_API_TOKEN" not in source


def test_no_obsolete_package_branding_in_release_metadata():
    text = PYPROJECT.read_text(encoding="utf-8").lower()

    assert "mech-lab" not in text
    assert "mech_lab" not in text
    assert "athian-agevidence-model" not in text


def test_v1_release_docs_keep_authority_and_trust_boundaries():
    release_docs = [
        SDK_ROOT / "README.md",
        SDK_ROOT / "docs" / "pypi.md",
        REPO_ROOT / "docs" / "releases" / "v1.0.0" / "RELEASE_NOTES.md",
    ]

    for path in release_docs:
        text = normalized_text(path.read_text(encoding="utf-8"))
        for term in AUTHORITY_BOUNDARY_TERMS:
            assert normalized_text(term) in text, f"{path} missing authority-boundary term {term}"
        for term in TRUST_BOUNDARY_TERMS:
            assert normalized_text(term) in text, f"{path} missing trust-boundary term {term}"
        assert normalized_text("Rust trust boundary") in text or normalized_text("Rust verifier") in text


def test_v1_release_workflow_is_pinned_and_uses_trusted_publishing():
    workflow = (REPO_ROOT / ".github" / "workflows" / "sdk-python-release.yml").read_text(encoding="utf-8")
    trigger = workflow.split("jobs:", 1)[0]

    assert "sdk-python-v1.0.0" in trigger
    assert "sdk-python-v*" not in trigger
    assert "id-token: write" in workflow
    assert "pypa/gh-action-pypi-publish@release/v1" in workflow
    assert "password:" not in workflow
    assert "api-token" not in workflow.lower()
    assert "bash scripts/agevidence_check_all.sh" in workflow
    assert "Fresh venv wheel smoke test" in workflow
    assert "Fresh venv sdist smoke test" in workflow

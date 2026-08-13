from __future__ import annotations

import tomllib
from pathlib import Path

from setuptools import find_packages


SDK_ROOT = Path(__file__).resolve().parents[1]
PYPROJECT = SDK_ROOT / "pyproject.toml"


def project_metadata():
    return tomllib.loads(PYPROJECT.read_text(encoding="utf-8"))


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
    assert (SDK_ROOT / "src" / "agevidence" / "py.typed").exists()
    assert (SDK_ROOT / "docs" / "pypi.md").exists()


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

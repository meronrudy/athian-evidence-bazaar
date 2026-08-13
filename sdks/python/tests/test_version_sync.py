from __future__ import annotations

import tomllib
from pathlib import Path

import agevidence


def test_pyproject_version_matches_package_version():
    pyproject = Path(__file__).resolve().parents[1] / "pyproject.toml"
    project = tomllib.loads(pyproject.read_text(encoding="utf-8"))["project"]

    assert project["version"] == agevidence.__version__

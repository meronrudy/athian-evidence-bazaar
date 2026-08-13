"""Deterministic synthetic fixture loader."""

from __future__ import annotations

import json
from importlib import resources
from pathlib import Path

from pydantic import BaseModel, ConfigDict


class Fixture(BaseModel):
    """A named synthetic fixture."""

    model_config = ConfigDict(extra="forbid")

    name: str
    primitive_type: str
    description: str
    payload: dict[str, object]


def fixture_names() -> list[str]:
    return sorted(path.name.removesuffix(".json") for path in _data_root().iterdir() if path.name.endswith(".json"))


def load_fixture(name: str) -> Fixture:
    path = _data_root().joinpath(f"{name}.json")
    if not path.is_file():
        raise ValueError(f"Unknown fixture: {name}")
    return Fixture.model_validate(json.loads(path.read_text(encoding="utf-8")))


def write_fixture(name: str, out: str | Path) -> Path:
    fixture = load_fixture(name)
    output = Path(out)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(fixture.payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return output


def _data_root():
    return resources.files("agevidence.fixtures").joinpath("data")

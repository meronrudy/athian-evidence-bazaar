"""Machine-readable SDK compatibility metadata."""

from __future__ import annotations

import json
from importlib import resources
from typing import Any


def compatibility_manifest() -> dict[str, Any]:
    """Return the packaged compatibility manifest."""

    return json.loads(resources.files("agevidence.resources").joinpath("compatibility-manifest.json").read_text(encoding="utf-8"))

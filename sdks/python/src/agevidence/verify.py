"""Public Rust verifier facade."""

from __future__ import annotations

import shlex
import shutil
from pathlib import Path

from agevidence.config import SDKConfig
from agevidence.models import VerifyResult
from agevidence.verification import Verifier


def verify(path: str | Path) -> VerifyResult:
    """Delegate bundle verification to the configured Rust verifier."""

    return Verifier().verify_bundle(path)


def rust_available(command: str | None = None) -> bool:
    """Return whether a configured Rust verifier command appears runnable."""

    configured = command or SDKConfig.load().verifier_command
    if configured:
        parts = shlex.split(configured)
        return bool(parts and (Path(parts[0]).exists() or shutil.which(parts[0])))
    for candidate in [Path("target/debug/baink-cli"), Path(__file__).resolve().parents[3] / "target" / "debug" / "baink-cli"]:
        if candidate.exists():
            return True
    return bool(shutil.which("baink-cli"))

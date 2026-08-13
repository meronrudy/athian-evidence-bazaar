#!/usr/bin/env python3
"""Read-only documentation hygiene checks for current AgEvidence claims."""

from __future__ import annotations

import re
import sys
from dataclasses import dataclass
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]

EXCLUDED_PARTS = {
    ".bundle",
    ".git",
    ".mypy_cache",
    ".pytest_cache",
    "__pycache__",
    "log",
    "node_modules",
    "storage",
    "target",
    "tmp",
    "vendor",
}

STALE_SDK_VERSIONS = {
    "0.2.0a1",
    "1.0.0rc",
}

HISTORICAL_TERMS = {
    "historical",
    "obsolete",
    "retained for audit context",
    "retained for context",
}


@dataclass(frozen=True)
class PatternCheck:
    pattern: re.Pattern[str]
    label: str


CURRENT_CLAIM_CHECKS = (
    PatternCheck(
        re.compile(r"\bevents?\s+(?:are\s+)?(?:immediately\s+)?verified\s+through\s+blockchain\b", re.I),
        "blockchain verification claim",
    ),
    PatternCheck(
        re.compile(r"\bsource\s+documents?\s+(?:are\s+)?stored\s+on\s+blockchain\b", re.I),
        "source records stored on blockchain claim",
    ),
    PatternCheck(
        re.compile(r"\bcross-chain\s+compatibility\b", re.I),
        "cross-chain claim",
    ),
    PatternCheck(
        re.compile(r"\bsmart\s+contracts?\b", re.I),
        "smart-contract rail claim",
    ),
    PatternCheck(
        re.compile(r"\bbuying/selling\s+verified\s+agricultural\s+evidence\b", re.I),
        "unsupported evidence marketplace claim",
    ),
    PatternCheck(
        re.compile(r"\b(?:develop|launch)\s+(?:a\s+)?(?:global\s+)?marketplace\b", re.I),
        "unsupported marketplace launch claim",
    ),
    PatternCheck(
        re.compile(r"\b50,000\+\s+head\b", re.I),
        "unproven pilot scale metric",
    ),
    PatternCheck(
        re.compile(r"\b40%\s+reduction\s+in\s+verification\s+costs\b", re.I),
        "unproven pilot savings metric",
    ),
    PatternCheck(
        re.compile(r"\b25%\s+increase\s+in\s+market\s+access\b", re.I),
        "unproven pilot impact metric",
    ),
    PatternCheck(
        re.compile(r"\b8\s+participating\s+companies\b", re.I),
        "unproven participation metric",
    ),
    PatternCheck(
        re.compile(r"\ball\s+pull\s+requests\s+require\s+at\s+least\s+2\s+approvals\b", re.I),
        "unsupported repository-governance claim",
    ),
    PatternCheck(
        re.compile(r"\bautomated\s+security\s+testing\s+in\s+ci/cd\s+pipeline\b", re.I),
        "unsupported CI/CD security claim",
    ),
    PatternCheck(
        re.compile(r"\bdoes\s+not\s+expose\s+a\s+`?\.github/workflows`?\s+ci\s+surface\b", re.I),
        "stale missing-CI claim",
    ),
    PatternCheck(
        re.compile(r"\bno\s+ci\s+pipeline\s+configured\b", re.I),
        "stale missing-CI claim",
    ),
    PatternCheck(
        re.compile(r"\bno\s+tagged\s+release\s+process\b", re.I),
        "stale missing-release-process claim",
    ),
)


def main() -> int:
    errors: list[str] = []
    for path in _markdown_files():
        text = path.read_text(encoding="utf-8")
        historical_document = _is_historical_document(text)
        for line_number, line in enumerate(text.splitlines(), start=1):
            if _is_allowed_historical_line(line):
                continue
            errors.extend(_check_sdk_versions(path, line_number, line, historical_document))
            errors.extend(_check_current_claims(path, line_number, line, historical_document))

    if errors:
        print("AgEvidence documentation hygiene failed:")
        for error in errors:
            print(error)
        return 1

    print("AgEvidence documentation hygiene passed")
    return 0


def _markdown_files() -> list[Path]:
    return sorted(
        path
        for path in REPO_ROOT.rglob("*.md")
        if not any(part in EXCLUDED_PARTS for part in path.relative_to(REPO_ROOT).parts)
    )


def _is_historical_document(text: str) -> bool:
    header = "\n".join(text.splitlines()[:8]).lower()
    return any(term in header for term in HISTORICAL_TERMS)


def _is_allowed_historical_line(line: str) -> bool:
    lowered = line.lower()
    return any(term in lowered for term in HISTORICAL_TERMS)


def _check_sdk_versions(path: Path, line_number: int, line: str, historical_document: bool) -> list[str]:
    if historical_document:
        return []
    return [
        _format_error(path, line_number, f"stale SDK version reference: {version}", line)
        for version in sorted(STALE_SDK_VERSIONS)
        if version in line
    ]


def _check_current_claims(path: Path, line_number: int, line: str, historical_document: bool) -> list[str]:
    if historical_document:
        return []
    return [
        _format_error(path, line_number, check.label, line)
        for check in CURRENT_CLAIM_CHECKS
        if check.pattern.search(line)
    ]


def _format_error(path: Path, line_number: int, label: str, line: str) -> str:
    relative = path.relative_to(REPO_ROOT)
    return f"- {relative}:{line_number}: {label}: {line.strip()}"


if __name__ == "__main__":
    raise SystemExit(main())

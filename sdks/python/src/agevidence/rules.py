"""Small deterministic evidence-property rules."""

from __future__ import annotations

from typing import Any

from pydantic import BaseModel, ConfigDict, Field


class RuleEvaluation(BaseModel):
    model_config = ConfigDict(extra="forbid")

    rule_id: str
    passed: bool
    findings: list[str] = Field(default_factory=list)


class Rule(BaseModel):
    """A local deterministic rule over evidence properties."""

    model_config = ConfigDict(extra="forbid")

    id: str
    require: dict[str, Any] = Field(default_factory=dict)

    def evaluate(self, value: Any) -> RuleEvaluation:
        context = _context(value)
        findings = []
        for key, expected in self.require.items():
            actual = context.get(key)
            if not _matches(actual, expected):
                findings.append(f"{key} expected {expected}, observed {actual}.")
        return RuleEvaluation(rule_id=self.id, passed=not findings, findings=findings)


def _context(value: Any) -> dict[str, Any]:
    context: dict[str, Any] = {}
    if hasattr(value, "coverage"):
        coverage = value.coverage()
        if isinstance(coverage, dict):
            context.update(coverage)
            context["coverage"] = coverage.get("coverage", coverage.get("ok"))
    if hasattr(value, "quality"):
        quality = value.quality()
        context.update(quality.model_dump(mode="json"))
    if isinstance(value, dict):
        context.update(value)
    return context


def _matches(actual: Any, expected: Any) -> bool:
    if isinstance(expected, dict):
        for op, value in expected.items():
            if op == ">=" and not (actual >= value):
                return False
            if op == ">" and not (actual > value):
                return False
            if op == "<=" and not (actual <= value):
                return False
            if op == "<" and not (actual < value):
                return False
            if op == "==" and not (actual == value):
                return False
            if op == "!=" and not (actual != value):
                return False
        return True
    return actual == expected

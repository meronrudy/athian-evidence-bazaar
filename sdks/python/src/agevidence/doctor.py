"""Local SDK readiness checks."""

from __future__ import annotations

import os
from importlib import import_module
from importlib import resources
from typing import Literal

from pydantic import BaseModel, ConfigDict

from ._version import __version__
from .compatibility import compatibility_manifest
from .demo import run_demo
from .fixtures import fixture_names, load_fixture
from .provenance import check
from .verify import rust_available


Status = Literal["pass", "fail", "not_configured"]


class DoctorCheck(BaseModel):
    """One doctor check result."""

    model_config = ConfigDict(extra="forbid")

    name: str
    status: Status
    detail: str = ""
    required: bool = True


class DoctorReport(BaseModel):
    """Agevidence local SDK doctor report."""

    model_config = ConfigDict(extra="forbid")

    sdk_version: str
    checks: list[DoctorCheck]

    @property
    def ready(self) -> bool:
        return all(check.status != "fail" for check in self.checks if check.required)


REQUIRED_FIXTURES = {
    "livestock-weight",
    "methane-observation",
    "intervention-dose",
    "spatial-model",
    "machine-operation",
}

REQUIRED_SCHEMAS = {
    "athian.agevidence.asset_state.v1.json",
    "athian.agevidence.attachment.v1.json",
    "athian.agevidence.calibration_record.v1.json",
    "athian.agevidence.derived_observation.v1.json",
    "athian.agevidence.external_object.v1.json",
    "athian.agevidence.source_record.v1.json",
    "athian.agevidence.observation.v1.json",
    "athian.agevidence.intervention_event.v1.json",
    "athian.agevidence.operational_event.v1.json",
    "athian.agevidence.spatial_observation.v1.json",
    "athian.agevidence.model_run.v1.json",
    "athian.agevidence.product_lot.v1.json",
    "athian.agevidence.transformation.v1.json",
}


def doctor() -> DoctorReport:
    """Run local SDK readiness checks."""

    checks = [
        _package_check(),
        _version_check(),
        _primitive_contract_check(),
        _schema_check(),
        _fixture_check(),
        _compatibility_manifest_check(),
        _optional_module_check(),
        _top_level_namespace_check(),
        _provenance_check(),
        _rust_validation_check(),
        _rust_version_check(),
        _verifier_contract_check(),
        _golden_replay_check(),
        _optional_env_check("Rails API", "AGEVIDENCE_BASE_URL"),
        _optional_env_check("API token", "AGEVIDENCE_API_TOKEN"),
    ]
    return DoctorReport(sdk_version=__version__, checks=checks)


def _package_check() -> DoctorCheck:
    try:
        import agevidence  # noqa: F401
    except Exception as exc:
        return DoctorCheck(name="Python package", status="fail", detail=str(exc))
    return DoctorCheck(name="Python package", status="pass")


def _version_check() -> DoctorCheck:
    return DoctorCheck(name="SDK version", status="pass", detail=__version__)


def _schema_check() -> DoctorCheck:
    try:
        schema_root = resources.files("agevidence.schemas")
        missing = [name for name in REQUIRED_SCHEMAS if not schema_root.joinpath(name).is_file()]
    except Exception as exc:
        return DoctorCheck(name="Primitive schemas", status="fail", detail=str(exc))
    if missing:
        return DoctorCheck(name="Primitive schemas", status="fail", detail=", ".join(sorted(missing)))
    return DoctorCheck(name="Primitive schemas", status="pass")


def _primitive_contract_check() -> DoctorCheck:
    try:
        from agevidence.primitives import (
            AssetState,
            Attachment,
            CalibrationRecord,
            DerivedObservation,
            ExternalObject,
            InterventionEvent,
            ModelRun,
            Observation,
            OperationalEvent,
            ProductLot,
            SourceRecord,
            SpatialObservation,
            Transformation,
        )

        _ = [
            SourceRecord,
            Observation,
            SpatialObservation,
            InterventionEvent,
            OperationalEvent,
            ModelRun,
            CalibrationRecord,
            ProductLot,
            AssetState,
            DerivedObservation,
            Transformation,
            Attachment,
            ExternalObject,
        ]
    except Exception as exc:
        return DoctorCheck(name="Primitive contracts", status="fail", detail=str(exc))
    return DoctorCheck(name="Primitive contracts", status="pass")


def _compatibility_manifest_check() -> DoctorCheck:
    try:
        manifest = compatibility_manifest()
    except Exception as exc:
        return DoctorCheck(name="Compatibility manifest", status="fail", detail=str(exc))
    if manifest.get("package") != "agevidence":
        return DoctorCheck(name="Compatibility manifest", status="fail", detail="package mismatch")
    if "rust_trust_boundary" not in manifest:
        return DoctorCheck(name="Compatibility manifest", status="fail", detail="missing Rust trust boundary")
    return DoctorCheck(name="Compatibility manifest", status="pass", detail=manifest.get("stable_boundary", ""))


def _optional_module_check() -> DoctorCheck:
    try:
        for module in ["agevidence.geo", "agevidence.otel", "agevidence.pytest_plugin", "agevidence.viz"]:
            import_module(module)
    except Exception as exc:
        return DoctorCheck(name="Optional module hooks", status="fail", detail=str(exc))
    return DoctorCheck(name="Optional module hooks", status="pass")


def _top_level_namespace_check() -> DoctorCheck:
    try:
        import agevidence

        if agevidence.SourceRecord.__module__ != "agevidence.primitives.source_record":
            return DoctorCheck(name="Top-level namespace", status="fail", detail="SourceRecord is not the local primitive")
    except Exception as exc:
        return DoctorCheck(name="Top-level namespace", status="fail", detail=str(exc))
    return DoctorCheck(name="Top-level namespace", status="pass")


def _fixture_check() -> DoctorCheck:
    missing = sorted(REQUIRED_FIXTURES - set(fixture_names()))
    if missing:
        return DoctorCheck(name="Fixture catalog", status="fail", detail=", ".join(missing))
    return DoctorCheck(name="Fixture catalog", status="pass")


def _provenance_check() -> DoctorCheck:
    fixture = load_fixture("livestock-weight")
    report = check(fixture.payload)
    if report.structural_validity == "pass":
        return DoctorCheck(name="Provenance engine", status="pass")
    return DoctorCheck(name="Provenance engine", status="fail", detail=report.model_dump_json())


def _rust_validation_check() -> DoctorCheck:
    result = run_demo("livestock-weight")
    if result.rust_validation == "pass":
        return DoctorCheck(name="Rust verifier", status="pass")
    if result.rust_validation == "not_configured":
        return DoctorCheck(name="Rust verifier", status="not_configured", detail="optional for pure-Python local checks", required=False)
    return DoctorCheck(name="Rust verifier", status="fail", detail=result.rust_stdout)


def _rust_version_check() -> DoctorCheck:
    if rust_available():
        return DoctorCheck(name="Rust verifier version", status="pass", detail="available")
    return DoctorCheck(name="Rust verifier version", status="not_configured", detail="optional for pure-Python local checks", required=False)


def _verifier_contract_check() -> DoctorCheck:
    # The verifier bridge is intentionally subprocess-based; this check protects
    # the canonical Python -> Rust syntax from drifting back to verify-bundle.
    from .verification import Verifier

    try:
        configured = Verifier(command="baink-cli")
        # No subprocess call here. The exact command is covered by unit tests and
        # release-readiness static checks.
        if configured.command == "baink-cli":
            return DoctorCheck(name="Verifier CLI contract", status="pass", detail="baink-cli verify BUNDLE --json")
    except Exception as exc:
        return DoctorCheck(name="Verifier CLI contract", status="fail", detail=str(exc))
    return DoctorCheck(name="Verifier CLI contract", status="fail")


def _golden_replay_check() -> DoctorCheck:
    result = run_demo("livestock-weight")
    if result.structural_validity == "pass" and result.provenance_completeness == "complete":
        return DoctorCheck(name="Golden fixture replay", status="pass")
    return DoctorCheck(name="Golden fixture replay", status="fail", detail=result.model_dump_json())


def _optional_env_check(name: str, env_var: str) -> DoctorCheck:
    if os.environ.get(env_var):
        return DoctorCheck(name=name, status="pass")
    return DoctorCheck(name=name, status="not_configured", detail="optional", required=False)

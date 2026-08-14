"""Wave 1/2 proof-kit registry and runners."""

from __future__ import annotations

import json
import os
import shlex
import subprocess
import tempfile
from collections.abc import Sequence
from importlib import resources
from pathlib import Path
from typing import Any

from agevidence.adapters import load_source_adapter, test_source_adapter
from agevidence.config import SDKConfig
from agevidence.primitives import EvidencePrimitive, local_digest
from agevidence.profiles import get_domain_profile

from .models import AUTHORITY_BOUNDARY, ProofKitMetadata, ProofRunResult, RustCommandResult


SCHEMA_BY_PRIMITIVE = {
    "SourceRecord": "source_record",
    "Observation": "observation",
    "SpatialObservation": "spatial_observation",
    "InterventionEvent": "intervention_event",
    "OperationalEvent": "operational_event",
    "ModelRun": "model_run",
}


def list_proofkits() -> list[ProofKitMetadata]:
    """Return all packaged Wave proof kits."""

    return list(_metadata_by_id().values())


def get_proofkit(proof_id: str) -> ProofKitMetadata:
    """Return metadata for one packaged proof kit."""

    try:
        return _metadata_by_id()[proof_id]
    except KeyError as exc:
        raise KeyError(f"Unknown proof kit: {proof_id}") from exc


def load_native_fixture(proof_id: str) -> dict[str, Any]:
    """Load a proof kit's native source fixture."""

    metadata = get_proofkit(proof_id)
    return _read_json(metadata.fixture)


def load_expected_output(proof_id: str) -> dict[str, Any]:
    """Load a proof kit's expected primitive output."""

    metadata = get_proofkit(proof_id)
    return _read_json(metadata.expected)


def run_proofkit(
    proof_id: str,
    *,
    rust_validate: bool = False,
    issue_receipt_projection: bool = False,
    verifier_command: str | None = None,
) -> ProofRunResult:
    """Run one proof kit through the local source-adapter harness."""

    metadata = get_proofkit(proof_id)
    fixture = load_native_fixture(proof_id)
    fixture_resource = resources.files(__package__).joinpath(metadata.fixture)
    with resources.as_file(fixture_resource) as fixture_path:
        report = test_source_adapter(metadata.adapter, fixture_path)
    adapter = load_source_adapter(metadata.adapter)
    primitives = _primitive_payloads(adapter.map(fixture))
    profile = get_domain_profile(metadata.profile_id)
    profile_applications = [profile.map(primitive).model_dump(mode="json", exclude_none=True) for primitive in primitives]
    rust_results = [
        _run_rust("validate", primitive, command=verifier_command)
        for primitive in primitives
    ] if rust_validate else []
    receipt_results = [
        _run_rust("issue", primitive, command=verifier_command)
        for primitive in primitives
    ] if issue_receipt_projection else []
    adapter_report = report.model_dump(mode="json", exclude_none=True)
    adapter_report["passed"] = report.passed
    return ProofRunResult(
        proof_id=metadata.id,
        company=metadata.company,
        wave=metadata.wave,
        generated_primitive=metadata.generated_primitive,
        domain_profile=metadata.domain_profile,
        profile_id=metadata.profile_id,
        downstream_beneficiaries=metadata.downstream_beneficiaries,
        native_source_record=metadata.native_source_record,
        primitives=primitives,
        profile_applications=profile_applications,
        local_digests=[local_digest(primitive) for primitive in primitives],
        adapter_report=adapter_report,
        rust_validation=rust_results,
        receipt_projections=receipt_results,
        authority_boundary=AUTHORITY_BOUNDARY,
    )


def write_proofkit(proof_id: str, out: str | Path) -> dict[str, str]:
    """Write a portable proof-kit fixture bundle to a local directory."""

    metadata = get_proofkit(proof_id)
    target = Path(out)
    target.mkdir(parents=True, exist_ok=True)
    paths = {
        "manifest": target / "manifest.json",
        "native": target / "native.json",
        "expected": target / "expected.json",
        "readme": target / "README.md",
        "adapter": target / "adapter.py",
    }
    paths["manifest"].write_text(json.dumps(metadata.model_dump(mode="json"), indent=2, sort_keys=True) + "\n", encoding="utf-8")
    paths["native"].write_text(json.dumps(load_native_fixture(proof_id), indent=2, sort_keys=True) + "\n", encoding="utf-8")
    paths["expected"].write_text(json.dumps(load_expected_output(proof_id), indent=2, sort_keys=True) + "\n", encoding="utf-8")
    paths["readme"].write_text(_read_text(metadata.readme), encoding="utf-8")
    paths["adapter"].write_text(_adapter_snippet(metadata), encoding="utf-8")
    return {key: str(path) for key, path in paths.items()}


def _metadata_by_id() -> dict[str, ProofKitMetadata]:
    raw = _read_json("metadata.json")
    items = [ProofKitMetadata.model_validate(item) for item in raw["proofkits"]]
    by_id: dict[str, ProofKitMetadata] = {}
    duplicates: set[str] = set()
    for item in items:
        if item.id in by_id:
            duplicates.add(item.id)
        by_id[item.id] = item
    if duplicates:
        raise ValueError(f"Duplicate proof kit ids: {', '.join(sorted(duplicates))}")
    return by_id


def _read_json(relative: str) -> Any:
    return json.loads(_read_text(relative))


def _read_text(relative: str) -> str:
    return resources.files(__package__).joinpath(relative).read_text(encoding="utf-8")


def _primitive_payloads(value: Any) -> list[dict[str, Any]]:
    if isinstance(value, EvidencePrimitive):
        return [value.to_payload()]
    if isinstance(value, dict):
        return [value]
    if isinstance(value, Sequence) and not isinstance(value, (str, bytes, bytearray)):
        payloads: list[dict[str, Any]] = []
        for item in value:
            payloads.extend(_primitive_payloads(item))
        return payloads
    raise TypeError("Proof-kit adapter returned an unsupported value")


def _run_rust(action: str, primitive: dict[str, Any], *, command: str | None) -> RustCommandResult:
    primitive_type = str(primitive.get("primitive_type"))
    schema = SCHEMA_BY_PRIMITIVE.get(primitive_type, primitive_type)
    executable = _rust_executable(command)
    with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False) as file:
        json.dump(primitive, file)
        path = Path(file.name)
    try:
        command_parts = [*executable, "agevidence", action, "--schema", schema, str(path)]
        if action == "issue":
            command_parts.extend(
                [
                    "--issuer",
                    "AgEvidence Wave Proof Kit",
                    "--signer",
                    "did:key:agevidence-wave-proof",
                    "--lifecycle",
                    "sealed",
                ]
            )
        completed = subprocess.run(command_parts, capture_output=True, text=True, check=False)
    except FileNotFoundError as exc:
        return RustCommandResult(
            action=action,  # type: ignore[arg-type]
            schema_name=schema,
            status="fail",
            command=[*executable, "agevidence", action],
            stderr=str(exc),
        )
    finally:
        path.unlink(missing_ok=True)

    payload = None
    if completed.stdout:
        try:
            payload = json.loads(completed.stdout)
        except json.JSONDecodeError:
            payload = None
    return RustCommandResult(
        action=action,  # type: ignore[arg-type]
        schema_name=schema,
        status="pass" if completed.returncode == 0 else "fail",
        command=command_parts,
        returncode=completed.returncode,
        stdout=completed.stdout,
        stderr=completed.stderr,
        payload=payload,
    )


def _rust_executable(command: str | None) -> list[str]:
    configured = command or os.environ.get("AGEVIDENCE_VERIFIER_COMMAND") or SDKConfig.load().verifier_command
    if configured:
        return shlex.split(configured)
    return [str(Path("target/debug/baink-cli"))]


def _adapter_snippet(metadata: ProofKitMetadata) -> str:
    _, class_name = metadata.adapter.split(":", 1)
    return (
        f'"""Local adapter entry point for {metadata.id}."""\n\n'
        f"from agevidence.proofkits.adapters import {class_name} as Adapter\n"
    )

"""Wave proof-kit models."""

from __future__ import annotations

from typing import Any, Literal

from pydantic import BaseModel, ConfigDict, Field


AUTHORITY_BOUNDARY = (
    "Proof kits validate local structure, provenance, deterministic representation, "
    "and canonical primitive compatibility. They do not establish regulatory eligibility, "
    "scientific validity, carbon-credit issuance, third-party verification, claim ownership, "
    "or institutional reliance."
)


class ProofKitMetadata(BaseModel):
    """Machine-readable metadata for a local Wave proof kit."""

    model_config = ConfigDict(extra="forbid")

    id: str
    company: str
    wave: str
    native_source_record: str
    generated_primitive: str
    domain_profile: str
    profile_id: str
    downstream_beneficiaries: list[str] = Field(default_factory=list)
    fixture: str
    expected: str
    adapter: str
    readme: str
    known_limitations: list[str] = Field(default_factory=list)


class RustCommandResult(BaseModel):
    """Result from a delegated Rust trust-boundary command."""

    model_config = ConfigDict(extra="forbid")

    action: Literal["validate", "issue"]
    schema_name: str
    status: Literal["not_requested", "pass", "fail"]
    command: list[str] = Field(default_factory=list)
    returncode: int | None = None
    stdout: str = ""
    stderr: str = ""
    payload: dict[str, Any] | None = None


class ProofRunResult(BaseModel):
    """Result from running one Wave proof kit locally."""

    model_config = ConfigDict(extra="forbid")

    proof_id: str
    company: str
    wave: str
    generated_primitive: str
    domain_profile: str
    profile_id: str
    downstream_beneficiaries: list[str] = Field(default_factory=list)
    native_source_record: str
    primitives: list[dict[str, Any]] = Field(default_factory=list)
    profile_applications: list[dict[str, Any]] = Field(default_factory=list)
    local_digests: list[str] = Field(default_factory=list)
    adapter_report: dict[str, Any]
    rust_validation: list[RustCommandResult] = Field(default_factory=list)
    receipt_projections: list[RustCommandResult] = Field(default_factory=list)
    signature_ready: bool = True
    production_signed: bool = False
    authority_boundary: str = AUTHORITY_BOUNDARY

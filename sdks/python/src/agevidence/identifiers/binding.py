"""Identifier binding helpers."""

from __future__ import annotations

from agevidence.identifiers.models import Identifier, IdentifierBinding


def build_binding(
    *,
    identifier_system: str,
    issuing_authority: str,
    local_value: str,
    global_subject: str,
    jurisdiction: str,
    source_commitment: str | None = None,
    limitations: list[str] | None = None,
) -> IdentifierBinding:
    """Create a complete identifier binding record."""

    return IdentifierBinding(
        identifier_system=identifier_system,
        issuing_authority=issuing_authority,
        local_value=local_value,
        global_subject=global_subject,
        source_commitment=source_commitment,
        jurisdiction=jurisdiction,
        limitations=limitations or [],
    )


def link(*identifiers: Identifier | str, global_subject: str | None = None) -> dict[str, object]:
    """Link local identifiers without requiring a central master-data system."""

    parsed = [_coerce(identifier) for identifier in identifiers]
    subject = global_subject or (f"agevidence:subject:{parsed[0].namespace}:{parsed[0].value}" if parsed else None)
    return {
        "global_subject": subject,
        "identifiers": [identifier.model_dump(mode="json") for identifier in parsed],
        "authority_boundary": "Identifier links are local bindings, not authority approval or certification.",
    }


def _coerce(identifier: Identifier | str) -> Identifier:
    if isinstance(identifier, Identifier):
        return identifier
    namespace, _, value = identifier.partition(":")
    if not namespace or not value:
        raise ValueError("Identifier strings must use namespace:value.")
    return Identifier(namespace=namespace, value=value)

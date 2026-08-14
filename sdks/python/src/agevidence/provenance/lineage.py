"""Lightweight provenance lineage graph models."""

from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, ConfigDict, Field

from agevidence.primitives import EvidencePrimitive, local_digest


LineageRelation = Literal[
    "derived_from",
    "generated_by",
    "observed_by",
    "applied_by",
    "references",
    "supersedes",
    "interprets",
    "allocates",
    "relies_on",
]


class EvidenceReference(BaseModel):
    """Portable reference to a committed evidence object."""

    model_config = ConfigDict(extra="forbid")

    commitment: str
    schema_id: str | None = None
    primitive_type: str | None = None
    uri: str | None = None


LineageValue = EvidencePrimitive | dict[str, object] | EvidenceReference | str


class LineageEdge(BaseModel):
    """Directed provenance relation between evidence objects."""

    model_config = ConfigDict(extra="forbid")

    relation: LineageRelation
    subject: EvidenceReference
    object: EvidenceReference
    metadata: dict[str, object] = Field(default_factory=dict)


class LineageGraph(BaseModel):
    """Small deterministic lineage DAG."""

    model_config = ConfigDict(extra="forbid")

    nodes: dict[str, dict[str, object]] = Field(default_factory=dict)
    edges: list[LineageEdge] = Field(default_factory=list)

    def add(self, value: LineageValue) -> EvidenceReference:
        """Add a node and return its reference."""

        ref, payload = _reference_and_payload(value)
        self.nodes.setdefault(ref.commitment, payload)
        return ref

    def derive(
        self,
        value: LineageValue,
        *,
        from_: LineageValue | list[LineageValue],
        relation: LineageRelation = "derived_from",
    ) -> EvidenceReference:
        """Record that `value` is derived from one or more inputs."""

        child = self.add(value)
        parents = from_ if isinstance(from_, list) else [from_]
        for parent_value in parents:
            parent = self.add(parent_value)
            self.edges.append(LineageEdge(relation=relation, subject=child, object=parent))
        return child

    def parents(self, node: LineageValue) -> list[EvidenceReference]:
        commitment = _commitment(node)
        return sorted([edge.object for edge in self.edges if edge.subject.commitment == commitment], key=lambda ref: ref.commitment)

    def children(self, node: LineageValue) -> list[EvidenceReference]:
        commitment = _commitment(node)
        return sorted([edge.subject for edge in self.edges if edge.object.commitment == commitment], key=lambda ref: ref.commitment)

    def roots(self) -> list[EvidenceReference]:
        children = {edge.subject.commitment for edge in self.edges}
        return sorted(
            [_reference_from_node(commitment, payload) for commitment, payload in self.nodes.items() if commitment not in children],
            key=lambda ref: ref.commitment,
        )

    def validate(self) -> list[str]:
        """Return graph validation errors."""

        errors: list[str] = []
        for edge in self.edges:
            if edge.subject.commitment not in self.nodes:
                errors.append(f"Missing subject node: {edge.subject.commitment}")
            if edge.object.commitment not in self.nodes:
                errors.append(f"Missing object node: {edge.object.commitment}")
        return errors

    def explain(self, node: EvidencePrimitive | dict[str, object] | EvidenceReference | str | None = None) -> str:
        """Explain graph lineage at a high level."""

        if node is None:
            return f"Lineage graph with {len(self.nodes)} node(s), {len(self.edges)} edge(s), and {len(self.roots())} root(s)."
        commitment = _commitment(node)
        return f"{commitment}: {len(self.parents(commitment))} parent(s), {len(self.children(commitment))} child(ren)."

    def to_manifest(self) -> dict[str, object]:
        """Return deterministic lineage manifest."""

        return {
            "nodes": [
                {"commitment": commitment, **dict(self.nodes[commitment])}
                for commitment in sorted(self.nodes)
            ],
            "edges": [
                edge.model_dump(mode="json", exclude_none=True)
                for edge in sorted(self.edges, key=lambda item: (item.subject.commitment, item.relation, item.object.commitment))
            ],
        }


def lineage() -> LineageGraph:
    """Create an empty local lineage graph."""

    return LineageGraph()


def _reference_and_payload(value: LineageValue) -> tuple[EvidenceReference, dict[str, object]]:
    if isinstance(value, EvidenceReference):
        return value, {}
    if isinstance(value, str):
        return EvidenceReference(commitment=value), {}
    payload = value.to_payload() if isinstance(value, EvidencePrimitive) else dict(value)
    commitment = str(payload.get("commitment") or payload.get("local_digest") or local_digest(payload))
    ref = EvidenceReference(
        commitment=commitment,
        schema_id=payload.get("schema_id") if isinstance(payload.get("schema_id"), str) else None,
        primitive_type=payload.get("primitive_type") if isinstance(payload.get("primitive_type"), str) else None,
        uri=payload.get("controlled_uri") if isinstance(payload.get("controlled_uri"), str) else None,
    )
    node = {
        key: value
        for key, value in {
            "schema_id": ref.schema_id,
            "primitive_type": ref.primitive_type,
            "uri": ref.uri,
        }.items()
        if value is not None
    }
    return ref, node


def _reference_from_node(commitment: str, payload: dict[str, object]) -> EvidenceReference:
    return EvidenceReference(
        commitment=commitment,
        schema_id=payload.get("schema_id") if isinstance(payload.get("schema_id"), str) else None,
        primitive_type=payload.get("primitive_type") if isinstance(payload.get("primitive_type"), str) else None,
        uri=payload.get("uri") if isinstance(payload.get("uri"), str) else None,
    )


def _commitment(value: LineageValue) -> str:
    if isinstance(value, str):
        return value
    return _reference_and_payload(value)[0].commitment

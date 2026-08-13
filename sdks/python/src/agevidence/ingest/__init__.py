"""Deterministic native-object ingest."""

from .infer import IngestResult, ingest
from .mappings import CandidateMapping, candidate_mappings

__all__ = ["CandidateMapping", "IngestResult", "candidate_mappings", "ingest"]

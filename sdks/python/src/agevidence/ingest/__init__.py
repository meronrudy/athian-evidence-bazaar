"""Deterministic native-object ingest."""

from .infer import IngestDataset, IngestResult, ingest, ingest_async, ingest_dataframe, ingest_file, ingest_many, ingest_stream
from .mappings import CandidateMapping, FieldMapping, MappingReport, SourceFieldCoverage, candidate_mappings, mapping_report, validate_extension_namespace

__all__ = [
    "CandidateMapping",
    "FieldMapping",
    "IngestDataset",
    "IngestResult",
    "MappingReport",
    "SourceFieldCoverage",
    "candidate_mappings",
    "ingest",
    "ingest_async",
    "ingest_dataframe",
    "ingest_file",
    "ingest_many",
    "ingest_stream",
    "mapping_report",
    "validate_extension_namespace",
]

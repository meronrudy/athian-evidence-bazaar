"""Offline/local Agevidence developer facade.

This namespace is below the thin waist: it works with fixtures, primitives,
local provenance checks, ingest helpers, and explanations without hosted
Agevidence services.
"""

from agevidence.demo import DemoResult, run_demo
from agevidence.doctor import DoctorCheck, DoctorReport, doctor
from agevidence.explain import ExplainReport, explain
from agevidence.exports import PortableEvidenceExport, export_evidence
from agevidence.fixtures import Fixture, fixture_names, load_fixture, write_fixture
from agevidence.frame import EvidenceFrame, frame
from agevidence.ingest import CandidateMapping, IngestDataset, IngestResult, candidate_mappings, ingest, ingest_async, ingest_dataframe, ingest_file, ingest_many, ingest_stream

__all__ = [
    "CandidateMapping",
    "DemoResult",
    "DoctorCheck",
    "DoctorReport",
    "EvidenceFrame",
    "ExplainReport",
    "Fixture",
    "IngestDataset",
    "IngestResult",
    "PortableEvidenceExport",
    "candidate_mappings",
    "doctor",
    "explain",
    "export_evidence",
    "fixture_names",
    "frame",
    "ingest",
    "ingest_async",
    "ingest_dataframe",
    "ingest_file",
    "ingest_many",
    "ingest_stream",
    "load_fixture",
    "run_demo",
    "write_fixture",
]

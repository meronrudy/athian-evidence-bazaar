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
from agevidence.ingest import CandidateMapping, IngestResult, candidate_mappings, ingest

__all__ = [
    "CandidateMapping",
    "DemoResult",
    "DoctorCheck",
    "DoctorReport",
    "ExplainReport",
    "Fixture",
    "IngestResult",
    "PortableEvidenceExport",
    "candidate_mappings",
    "doctor",
    "explain",
    "export_evidence",
    "fixture_names",
    "ingest",
    "load_fixture",
    "run_demo",
    "write_fixture",
]

"""AgEvidence Python SDK.

The SDK exposes local evidence primitives and developer tooling without
requiring hosted Agevidence services. Hosted control-plane clients remain
available from the top-level package through lazy compatibility exports.
"""

from __future__ import annotations

from importlib import import_module
from typing import Any

from ._version import __version__
from .assessment import Assessment, assess
from .bundle import Bundle, BundleSummary, BundleValidationReport
from .compatibility import compatibility_manifest
from .demo import run_demo as demo
from .diff import SemanticDiff, diff
from .doctor import doctor
from .errors import AgEvidenceError
from .findings import Finding
from .frame import EvidenceFrame, frame
from .ingest import IngestDataset, IngestResult, ingest, ingest_async, ingest_dataframe, ingest_file, ingest_many, ingest_stream
from .offline import Queue
from .primitives import AssetState, Attachment, CalibrationRecord, DerivedObservation, ExternalObject, ProductLot, SourceRecord, Transformation
from .provenance import LineageGraph, lineage
from .quality import EvidenceQuality, quality
from .replay import ReplayResult, replay
from .rules import Rule, RuleEvaluation
from .series import EvidenceSeries, series
from .snapshots import SnapshotReport, check_snapshot, create_snapshot
from .units import Quantity, compatible_units, normalize_unit, validate_unit
from .verify import rust_available, verify

_LAZY_EXPORTS = {
    "AgEvidenceRequest": ("agevidence.request_models", "AgEvidenceRequest"),
    "ArtifactDownloadMetadata": ("agevidence.models", "ArtifactDownloadMetadata"),
    "ArtifactOrder": ("agevidence.models", "ArtifactOrder"),
    "AsyncClient": ("agevidence.async_client", "AsyncClient"),
    "ActivationPath": ("agevidence.campaign", "ActivationPath"),
    "CampaignAccount": ("agevidence.campaign", "CampaignAccount"),
    "CampaignClient": ("agevidence.campaign", "CampaignClient"),
    "CampaignContactRef": ("agevidence.campaign", "CampaignContactRef"),
    "CampaignDashboard": ("agevidence.campaign", "CampaignDashboard"),
    "Client": ("agevidence.client", "Client"),
    "CommercialHandoff": ("agevidence.campaign", "CommercialHandoff"),
    "CountryAdapterInfo": ("agevidence.models", "CountryAdapterInfo"),
    "CountryAdapterValidation": ("agevidence.models", "CountryAdapterValidation"),
    "CountryDetermination": ("agevidence.models", "CountryDetermination"),
    "DeveloperProject": ("agevidence.models", "DeveloperProject"),
    "EvidenceCandidate": ("agevidence.models", "EvidenceCandidate"),
    "IntegrationEventStatus": ("agevidence.models", "IntegrationEventStatus"),
    "Operation": ("agevidence.models", "Operation"),
    "PricingQuote": ("agevidence.models", "PricingQuote"),
    "ProductCatalog": ("agevidence.models", "ProductCatalog"),
    "RetryPolicy": ("agevidence.transport", "RetryPolicy"),
    "TechnicalQualification": ("agevidence.campaign", "TechnicalQualification"),
    "WebhookEndpoint": ("agevidence.models", "WebhookEndpoint"),
}

__all__ = [
    "AgEvidenceError",
    "AgEvidenceRequest",
    "ActivationPath",
    "Assessment",
    "AssetState",
    "ArtifactDownloadMetadata",
    "ArtifactOrder",
    "AsyncClient",
    "Attachment",
    "Bundle",
    "BundleSummary",
    "BundleValidationReport",
    "CalibrationRecord",
    "CampaignAccount",
    "CampaignClient",
    "CampaignContactRef",
    "CampaignDashboard",
    "Client",
    "CommercialHandoff",
    "CountryAdapterInfo",
    "CountryAdapterValidation",
    "CountryDetermination",
    "DeveloperProject",
    "DerivedObservation",
    "demo",
    "diff",
    "doctor",
    "EvidenceFrame",
    "EvidenceQuality",
    "EvidenceCandidate",
    "EvidenceSeries",
    "ExternalObject",
    "Finding",
    "frame",
    "IntegrationEventStatus",
    "ingest",
    "ingest_async",
    "ingest_dataframe",
    "ingest_file",
    "ingest_many",
    "ingest_stream",
    "IngestDataset",
    "IngestResult",
    "LineageGraph",
    "Operation",
    "PricingQuote",
    "ProductCatalog",
    "ProductLot",
    "Quantity",
    "Queue",
    "RetryPolicy",
    "ReplayResult",
    "Rule",
    "RuleEvaluation",
    "SemanticDiff",
    "SourceRecord",
    "assess",
    "check_snapshot",
    "compatibility_manifest",
    "compatible_units",
    "create_snapshot",
    "normalize_unit",
    "lineage",
    "quality",
    "replay",
    "rust_available",
    "series",
    "TechnicalQualification",
    "Transformation",
    "validate_unit",
    "verify",
    "WebhookEndpoint",
    "__version__",
]


def __getattr__(name: str) -> Any:
    """Load hosted/control-plane compatibility exports only when requested."""

    try:
        module_name, attribute = _LAZY_EXPORTS[name]
    except KeyError as exc:
        raise AttributeError(f"module 'agevidence' has no attribute {name!r}") from exc
    value = getattr(import_module(module_name), attribute)
    globals()[name] = value
    return value


def __dir__() -> list[str]:
    return sorted(set(globals()) | set(__all__))

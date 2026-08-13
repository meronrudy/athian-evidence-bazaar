"""AgEvidence Python SDK.

The SDK exposes local evidence primitives and developer tooling without
requiring hosted Agevidence services. Hosted control-plane clients remain
available from the top-level package through lazy compatibility exports.
"""

from __future__ import annotations

from importlib import import_module
from typing import Any

from ._version import __version__
from .demo import run_demo as demo
from .doctor import doctor
from .errors import AgEvidenceError
from .ingest import ingest

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
    "SourceRecord": ("agevidence.models", "SourceRecord"),
    "TechnicalQualification": ("agevidence.campaign", "TechnicalQualification"),
    "WebhookEndpoint": ("agevidence.models", "WebhookEndpoint"),
}

__all__ = [
    "AgEvidenceError",
    "AgEvidenceRequest",
    "ActivationPath",
    "ArtifactDownloadMetadata",
    "ArtifactOrder",
    "AsyncClient",
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
    "demo",
    "doctor",
    "EvidenceCandidate",
    "IntegrationEventStatus",
    "ingest",
    "Operation",
    "PricingQuote",
    "ProductCatalog",
    "RetryPolicy",
    "SourceRecord",
    "TechnicalQualification",
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

"""Interpretation profile facade.

Profiles evaluate evidence without owning or rewriting the evidence. Existing
country adapter APIs remain available through compatibility modules; this
namespace is the preferred import surface for interpretation plugins.
"""

from agevidence.adapters.base import AdapterEvaluationResult, AdapterMetadata, CountryAdapter
from agevidence.adapters.registry import AdapterRegistry, default_registry
from agevidence.policies.models import PolicyResolution, PolicyResolutionResult, PolicyStackEntry
from agevidence.profiles.domain import (
    BioactiveProductLot,
    DomainProfile,
    DomainProfileApplication,
    DomainProfileMetadata,
    EntericMethaneMeasurement,
    FeedAdditiveDelivery,
    ObjectiveCarcassMeasurement,
    PrecisionChemicalApplication,
    SpatialBiomassObservation,
    SpatialDigitalTwinManifest,
    WaterDosingIntervention,
)
from agevidence.profiles.domain_registry import DomainProfileRegistry, default_domain_registry, get_domain_profile, list_domain_profiles

__all__ = [
    "AdapterEvaluationResult",
    "AdapterMetadata",
    "AdapterRegistry",
    "BioactiveProductLot",
    "CountryAdapter",
    "default_domain_registry",
    "DomainProfile",
    "DomainProfileApplication",
    "DomainProfileMetadata",
    "DomainProfileRegistry",
    "EntericMethaneMeasurement",
    "FeedAdditiveDelivery",
    "get_domain_profile",
    "list_domain_profiles",
    "ObjectiveCarcassMeasurement",
    "PrecisionChemicalApplication",
    "PolicyResolution",
    "PolicyResolutionResult",
    "PolicyStackEntry",
    "SpatialBiomassObservation",
    "SpatialDigitalTwinManifest",
    "WaterDosingIntervention",
    "default_registry",
]

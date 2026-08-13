"""Interpretation profile facade.

Profiles evaluate evidence without owning or rewriting the evidence. Existing
country adapter APIs remain available through compatibility modules; this
namespace is the preferred import surface for interpretation plugins.
"""

from agevidence.adapters.base import AdapterEvaluationResult, AdapterMetadata, CountryAdapter
from agevidence.adapters.registry import AdapterRegistry, default_registry
from agevidence.policies.models import PolicyResolution, PolicyResolutionResult, PolicyStackEntry

__all__ = [
    "AdapterEvaluationResult",
    "AdapterMetadata",
    "AdapterRegistry",
    "CountryAdapter",
    "PolicyResolution",
    "PolicyResolutionResult",
    "PolicyStackEntry",
    "default_registry",
]

"""Livestock domain value objects for Australian evidence adapters."""

from __future__ import annotations

from pydantic import BaseModel, ConfigDict

from .primitives import InterventionEvent, Observation


class LivestockModel(BaseModel):
    model_config = ConfigDict(extra="allow")


class Animal(LivestockModel):
    animal_id: str
    species: str
    identifiers: list[str] = []


class Herd(LivestockModel):
    herd_id: str
    species: str
    production_system: str | None = None


class Intervention(LivestockModel):
    intervention_id: str
    intervention_type: str
    occurred_at: str | None = None


class FeedAdditive(Intervention):
    product_id: str | None = None
    product_batch: str | None = None
    dose_or_quantity: str | None = None
    unit: str | None = None

    def to_intervention_event(self, *, target: str) -> InterventionEvent:
        return InterventionEvent(
            target=target,
            intervention=self.product_id or self.intervention_type,
            quantity=self.dose_or_quantity,
            unit=self.unit or "unspecified",
            occurred_at=self.occurred_at or "",
            batch=self.product_batch,
            metadata={
                "livestock_intervention_id": self.intervention_id,
                "livestock_intervention_type": self.intervention_type,
            },
        )


class Movement(LivestockModel):
    movement_id: str
    from_location: str | None = None
    to_location: str | None = None
    moved_at: str | None = None


class Weight(LivestockModel):
    subject_id: str
    value: str
    unit: str
    measured_at: str | None = None

    def to_observation(self) -> Observation:
        return Observation(
            subject=self.subject_id,
            observable="liveweight",
            value=self.value,
            unit=self.unit,
            observed_at=self.measured_at or "",
        )


class Milk(LivestockModel):
    subject_id: str
    volume: str
    unit: str
    measured_at: str | None = None

    def to_observation(self) -> Observation:
        return Observation(
            subject=self.subject_id,
            observable="milk_volume",
            value=self.volume,
            unit=self.unit,
            observed_at=self.measured_at or "",
        )


class MethaneObservation(LivestockModel):
    subject_id: str
    value: str
    unit: str
    method: str | None = None
    observed_at: str | None = None

    def to_observation(self) -> Observation:
        return Observation(
            subject=self.subject_id,
            observable="enteric_methane",
            value=self.value,
            unit=self.unit,
            observed_at=self.observed_at or "",
            method=self.method,
        )


class NLISIdentifier(LivestockModel):
    value: str
    issuer: str = "NLIS"
    status: str = "unverified"

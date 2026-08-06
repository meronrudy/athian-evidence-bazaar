# DIT AgTech Reference Workspace
> **Status:** Public-information design hypothesis  
> **Company participation:** Not confirmed  
> **Affiliation:** None  
> **Endorsement:** None  
> **Data:** Synthetic or publicly described only

## Purpose
This workspace uses publicly available information about DIT AgTech as a reference case for designing event-first agricultural evidence infrastructure. It is intended to test whether AgEvidence's open schemas can represent:
- device installation and calibration;
- supplement batch provenance;
- water-point telemetry;
- intervention-delivery records;
- methodology interpretation;
- assurance and reliance outputs.

This workspace does not claim to describe DIT AgTech's internal systems completely or accurately.

## Invitation to review
DIT AgTech and other domain experts are invited to:
- correct inaccurate terminology;
- identify missing or invalid events;
- recommend safer data boundaries;
- review the proposed event contract;
- contribute synthetic fixtures;
- propose changes through issues or pull requests.

Participation is voluntary, public and non-commercial.

## Open Questions
### Observation semantics
- Does the system record intended dosing, observed dosing or both?
- Is supplement volume directly metered or inferred from tank depletion?
- What event marks an interrupted dosing period?
- How is sensor drift represented?

### Identity
- Which identifier is stable: device, water point, property or customer?
- Can devices move between water points?
- How are replacement devices represented?

### Calibration
- Is calibration performed centrally, during installation or periodically?
- Which calibration records need to remain externally referenceable?
- Can a digest and metadata summary replace the underlying record?

### Authority
- Who is authorized to export telemetry?
- Who can state that a device was installed for a particular project?
- How should customer permission be represented?

### Claim boundaries
- What can telemetry establish directly?
- What requires model interpretation?
- What requires biological or scientific validation?
- What requires verifier determination?
# Open Agricultural Evidence Protocol (OAEP) Specification v1.0.0

## Protocol Overview
The OAEP standard defines a neutral framework for agricultural evidence management, enabling interoperable, decentralized verification of agricultural data without centralized coordination.

## Core Components
1. **Event Envelope (oaep.event-envelope.v1)**
   - Standardized format for recording agricultural interventions
   - Includes: intervention type, location, timing, and evidence sources

2. **Source Manifest (oaep.source-manifest.v1)**
   - Cryptographic record of evidence origin
   - Contains: content digest, schema identifier, custodian details, and transformation history

3. **Authority Grant (oaep.authority-grant.v1)**
   - Formal authorization for evidence use
   - Defines: authority type, scope, validity period, and revocation conditions

4. **Verification Determination (oaep.verification-determination.v1)**
   - Independent assessment of evidence validity
   - Includes: verifier identity, procedures performed, and final determination

## Security Requirements
- All components must implement Ed25519 signatures with SHA-512
- Content digests use SHA-256
- Keys rotated every 90 days
- TLS 1.3 for all communications

## Versioning
- Semantic versioning (MAJOR.MINOR.PATCH)
- Backward compatibility maintained through versioned identifiers
- Deprecation policy in VERSIONING.md

## Governance
- Public RFC process for changes
- Security Committee oversees cryptographic standards
- Compliance Team manages regulatory mappings

## Compatibility
- No Athian-specific identifiers allowed
- Legacy aliases maintained in alias registry
- All implementations must support content-addressed packages
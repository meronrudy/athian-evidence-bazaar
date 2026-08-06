# OAEP Neutral Identifiers

## Core Schema Identifiers
- `oaep.receipt-envelope.v1`
  - Event envelope schema for agricultural interventions
- Versioned for backward compatibility

- `oaep.source-manifest.v1`
  - Cryptographic record of evidence origin
- Includes content digest and custodian details

- `oaep.authority-grant.v1`
  - Formal authorization for evidence use
- Defines scope and validity period

- `oaep.verification-determination.v1`
  - Independent assessment of evidence validity
- Includes verifier identity and procedures

## Versioning Pattern
All identifiers follow `oaep.<component>.<version>` format
- MAJOR version changes indicate breaking schema changes
- MINOR versions add new features or fields
- PATCH versions fix bugs or clarify documentation

## Legacy Alias Mappings
| Legacy Identifier | Canonical Identifier | Compatible Through |
|-------------------|----------------------|-------------------|
| `athian.agevidence.model_execution.v1` | `oaep.model-execution.v1` | `oaep/1.x` |
| `athian.agevidence.receipt_envelope.v1` | `oaep.receipt-envelope.v1` | `oaep/1.x` |
| `athian.agevidence.source_manifest.v1` | `oaep.source-manifest.v1` | `oaep/1.x` |
| `athian.agevidence.authority_grant.v1` | `oaep.authority-grant.v1` | `oaep/1.x` |
| `athian.agevidence.verification_determination.v1` | `oaep.verification-determination.v1` | `oaep/1.x` |

## Compatibility Rules
- No Athian-specific identifiers allowed in new implementations
- Legacy aliases maintained for backward compatibility
- All implementations must support content-addressed packages
- Versioned identifiers ensure clear upgrade paths
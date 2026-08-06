# OAEP Versioning Policy

## Version Format
All OAEP identifiers follow semantic versioning: `MAJOR.MINOR.PATCH`

## Identifier Format
```
oaep.<component>.<version>
```

Examples:
- `oaep.event-envelope.v1`
- `oaep.source-manifest.v1`
- `oaep.authority-grant.v1`
- `oaep.verification-determination.v1`

## Version Lifecycle

### MAJOR Versions
- Breaking changes to schema structure
- New required fields
- Removal of deprecated fields
- Changes to canonicalization rules

### MINOR Versions
- New optional fields
- New vocabulary values
- New adapter profiles
- Extended validation rules

### PATCH Versions
- Bug fixes
- Clarifications
- Documentation updates
- Test vector additions

## Compatibility Rules

### Forward Compatibility
- Implementations MUST accept newer MINOR/PATCH versions of schemas they support
- Unknown fields MUST be preserved during round-trip operations

### Backward Compatibility
- MAJOR versions are NOT backward compatible
- MINOR versions are backward compatible within same MAJOR
- PATCH versions are fully backward compatible

## Deprecation Policy
1. Deprecation announced in MINOR release
2. Minimum 6-month deprecation period
3. Removal in next MAJOR release
4. Migration guide provided for each deprecation

## Legacy Alias Registry
Legacy Athian identifiers are mapped to OAEP canonical identifiers:

| Legacy Identifier | Canonical Identifier | Compatible Through |
|-------------------|---------------------|-------------------|
| `athian.agevidence.model_execution.v1` | `oaep.model-execution.v1` | `oaep/1.x` |
| `athian.agevidence.receipt_envelope.v1` | `oaep.receipt-envelope.v1` | `oaep/1.x` |
| `athian.agevidence.source_manifest.v1` | `oaep.source-manifest.v1` | `oaep/1.x` |
| `athian.agevidence.authority_grant.v1` | `oaep.authority-grant.v1` | `oaep/1.x` |
| `athian.agevidence.verification_determination.v1` | `oaep.verification-determination.v1` | `oaep/1.x` |

## Release Process
1. Proposal via RFC
2. Public review period (30 days minimum)
3. Security Committee review
4. Governance approval
5. Release with migration guide
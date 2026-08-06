# Open Agricultural Evidence Protocol (OAEP)

## Overview
The OAEP standard defines a neutral protocol for agricultural evidence management, enabling interoperability between independent implementations without requiring centralized coordination.

## Key Features
- **Decentralized Verification**: Evidence bundles can be verified by any qualified verifier without relying on a central platform
- **Schema Neutrality**: No schema requires proprietary identifiers or dependencies
- **Portable Packages**: Evidence can be distributed as content-addressed packages
- **Multi-Party Transactions**: Supports end-to-end producer-to-buyer workflows without intermediaries

## Versioning
- Current version: 1.0.0
- Backward compatibility maintained through versioned identifiers

## Governance
- Public RFC process for protocol changes
- Security Committee oversees cryptographic standards
- Compliance Team manages regulatory mappings

## Security
- All implementations must follow the security measures outlined in SECURITY.md
- Third-party audits required annually
- Bug bounty program for vulnerability reporting

## Implementation
- Reference implementation available in Rust and TypeScript
- Adapters available for Australian agricultural data
- CLI tools for validation and verification

## Compatibility
- Maintains backward compatibility with Athian implementations through legacy alias mappings
- New implementations should avoid Athian-specific identifiers
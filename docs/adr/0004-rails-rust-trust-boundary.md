# ADR 0004: Rails/Rust Trust Boundary

Status: Accepted

Rails projects domain workflow state and calls the `ink_receipts` facade. Generic Rust crates remain the receipt, canonicalization, bundle, and verification trust boundary. Country-specific behavior must not be introduced into generic Rust crates.

Rust may validate stable AgEvidence domain payload shapes. It must not interpret national policy, external authority decisions, or institution-specific reliance.


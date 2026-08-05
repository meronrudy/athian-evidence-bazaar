# ADR 0005: Append-Only Country Determinations

Status: Accepted

Country determinations are immutable once created. Any change in evidence, adapter version, policy profile, external check result, or institution requirement must create a new determination that supersedes the prior determination.

The database model enforces this with update and destroy prevention. Local gates also scan application code for direct determination mutation paths.


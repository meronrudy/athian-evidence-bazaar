# ADR 0006: Country-Pack Versioning

Status: Accepted

Country packs are versioned declarative profiles. Adapter id, adapter version, method id, method version, source profile versions, policy profile ids, artifact profile ids, and limitations must be explicit in the manifest or resolved determination output.

Syntactically valid YAML is not enough for implementation status. Packs are classified as `active`, `pilot`, `scaffold`, `research`, or `invalid` by the manifest validator.


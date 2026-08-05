# Python Country Plugin Guide

Executable country plugins implement `agevidence.adapters.base.CountryAdapter`.

Required methods:

- `normalize_identifier`
- `normalize_source_record`
- `validate_local_context`
- `evidence_requirements`
- `external_checks`
- `policy_stack`

Installed plugins are discovered through the `agevidence.country_adapters` Python entry-point group. Local development plugins may be loaded by module path through the registry, for example `package.module:AdapterFactory`. Adapter YAML files must not load code.

Plugin outputs may emit findings such as `valid_format`, `source_found`, `external_check_unavailable`, `review_required`, and `conflict`. They must not claim approval, certification, or institutional reliance.


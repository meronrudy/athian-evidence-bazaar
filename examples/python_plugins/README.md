# Python Plugin Examples

The test suite includes a synthetic entry-point loading path through `agevidence.adapters.loader`.

New plugins should expose a factory returning a `CountryAdapter` implementation and should be registered under the `agevidence.country_adapters` entry-point group when packaged.


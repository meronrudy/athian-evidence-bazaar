# Wave 1/2 Proof Kits

Wave proof kits are local, no-account developer proofs for the supplied
Australian adoption matrix. Each kit maps one synthetic native source record
into existing canonical Agevidence primitives through the source-adapter
harness.

```bash
agevidence proof list
agevidence proof run dit.water_dosing_intervention --format table
agevidence proof write dit.water_dosing_intervention --out ./dit-proof
```

Optional Rust delegation stays behind the trust boundary:

```bash
agevidence proof run dit.water_dosing_intervention --rust-validate
agevidence proof run dit.water_dosing_intervention --issue-receipt-projection
```

`--rust-validate` calls `baink-cli agevidence validate`. `--issue-receipt-projection`
calls `baink-cli agevidence issue`. The Python SDK does not implement receipt
signing, dCBOR, or bundle verification internally.

## Proof Matrix

| Proof kit | Company | Native source record | Generated primitive | Reusable domain profile |
| --- | --- | --- | --- | --- |
| `dit.water_dosing_intervention` | DIT AgTech | Water flow pulses, dosing pump rate, tank conductivity | `InterventionEvent` | `WaterDosingIntervention` |
| `meq.objective_carcass_measurement` | MEQ Solutions | Hyperspectral carcass needle reflectance | `Observation` | `ObjectiveCarcassMeasurement` |
| `agscent.enteric_methane_measurement` | Agscent | Breath VOC sensor array and UART sample | `Observation` | `EntericMethaneMeasurement` |
| `cibo.spatial_biomass_observation` | Cibo Labs | Spatial biomass and fractional-cover model output | `SpatialObservation` | `SpatialBiomassObservation` |
| `agronomeye.spatial_digital_twin_manifest` | Agronomeye | LiDAR and multispectral digital twin manifest | `SourceRecord` | `SpatialDigitalTwinManifest` |
| `rumin8.feed_additive_delivery_manifest` | Rumin8 | Feed additive delivery receipt | `InterventionEvent` | `FeedAdditiveDelivery` |
| `sea_forest.bioactive_product_lot_manifest` | Sea Forest | Bioactive product lot CSV row | `InterventionEvent` | `BioactiveProductLot` |
| `swarmfarm.precision_chemical_application` | SwarmFarm Robotics | Autonomous spray telemetry | `OperationalEvent` | `PrecisionChemicalApplication` |

Reusable domain profile names are adapter/proof-kit capabilities. They are not
new canonical schema types, and the proof kits do not add event-inbox schemas.

## What A Local Proof Establishes

A passing proof establishes that a partner-shaped native payload can be mapped
deterministically into canonical primitives, can pass local provenance checks,
and can be validated by Rust where a verifier command is available.

It does not establish regulatory eligibility, scientific validity,
carbon-credit issuance, third-party verification, claim ownership, or
institutional reliance.

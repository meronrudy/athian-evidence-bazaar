# Rumin8 - Product Documentation

## Company Overview
Rumin8 ranks fifth with a priority score of 32. They develop livestock methane-inhibiting feed additives based on synthesized organic chemistry reproducing naturally occurring halogenated compounds. Rumin8 is supported by Breakthrough Energy Ventures, Harvest Road, and AgriZeroNZ. The company's technology was validated through a 120-day feedlot trial in Brazil with Minerva Foods, generating verified Scope 3 insets.

## Product Portfolio
- **Methane-inhibiting feed additives**: Based on synthesized organic chemistry

## Business Model
- Develops feed additives that reduce livestock methane emissions
- Validated through feedlot trials with major meat processors
- Generates verified Scope 3 insets

## Technical Architecture
- Active compound batch synthesis and QA purity assays enter as Class B source records
- Formulation lot releases enter as Class B source records
- Ration inclusion logs emit intervention.recorded
- Trial methane results emit model.run_completed
- Inset credit allocations emit verification.status_changed

## Target Customers
- Livestock producers
- Feedlot operators
- Meat processors
- Carbon project developers

## Evidence Lifecycle
1. **Compound Synthesis**: Batch synthesis and QA assays as Class B source records
2. **Formulation Release**: Lot releases as Class B source records
3. **Ration Inclusion**: Logs as intervention.recorded
4. **Trial Results**: Methane measurements as model.run_completed
5. **Credit Allocation**: Inset credits as verification.status_changed

## Key Integration Points
- Feed manufacturing systems
- Livestock management platforms
- Trial data collection systems
- Carbon credit registries
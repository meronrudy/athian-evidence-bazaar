# Cibo Labs - Product Documentation

## Company Overview
Cibo Labs ranks fourth with a priority score of 33. They deliver satellite-derived pasture biomass, fractional ground cover, and land-condition intelligence (PastureKey) across Australian livestock properties. Cibo Labs converts Earth observations and ground-truth calibration data into paddock-scale forage estimates for pastoralists, banks, insurers, and carbon project developers.

## Product Portfolio
- **PastureKey**: Satellite-derived pasture biomass and land-condition intelligence

## Business Model
- Converts Earth observations and ground-truth calibration data into paddock-scale forage estimates
- Targets pastoralists, banks, insurers, and carbon project developers

## Technical Architecture
- Satellite scene metadata and cloud masks commit as Class B source manifests
- Biomass model runs emit model.run_completed
- Spatial paddock boundary aggregations require a spatial profile

## Target Customers
- Pastoralists
- Banks
- Insurers
- Carbon project developers

## Evidence Lifecycle
1. **Satellite Data**: Scene metadata and cloud masks as Class B source manifests
2. **Biomass Model Runs**: model.run_completed
3. **Spatial Aggregation**: Paddock boundary aggregations

## Key Integration Points
- Satellite data providers
- Ground truth collection systems
- Farm management platforms
- Carbon accounting systems
# Agscent - Product Documentation

## Company Overview
Agscent ranks third with a priority score of 34. They utilize NASA-derived breath collection devices and multi-channel nanosensors for livestock emissions measurement (Agscent Air) and point-of-care diagnostics (Agscent Breath). Agscent partners with Dairy Farmers of America, Optiweigh, Macquarie University, and the Australian National University.

## Product Portfolio
- **Agscent Air**: Livestock emissions measurement via breath collection
- **Agscent Breath**: Point-of-care diagnostics

## Business Model
- Partners with feed-additive trial sponsors, cattle breeding programs, and Scope 3 auditors
- Combines breath collection hardware with grazing equipment for methane/carbon dioxide profiling

## Technical Architecture
- Animal RFID and weight readings enter via identity extensions
- Raw channel vectors commit as Class B source manifests
- AI emissions estimations emit model.run_completed

## Target Customers
- Feed-additive trial sponsors
- Cattle breeding programs
- Scope 3 auditors

## Evidence Lifecycle
1. **Breath Collection**: Raw channel vectors as Class B source manifests
2. **AI Emissions Estimation**: model.run_completed
3. **Auditor Review**: Verification status changes

## Key Integration Points
- Livestock RFID systems
- Agricultural sensor networks
- Carbon audit platforms
- Research data repositories
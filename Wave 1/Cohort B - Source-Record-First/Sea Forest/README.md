# Sea Forest - Product Documentation

## Company Overview
Sea Forest shares the fifth rank with a priority score of 32. They cultivate Asparagopsis seaweed and manufacture SeaFeed supplement oil and solid fractions. Sea Forest operates commercial marine and land aquaculture facilities and holds a Verra-listed grouped project.

## Product Portfolio
- **SeaFeed Supplement Oil**: Asparagopsis-derived feed supplement
- **SeaFeed Solid Fractions**: Asparagopsis-derived feed supplement

## Business Model
- Cultivates Asparagopsis seaweed in commercial marine and land aquaculture facilities
- Manufactures feed supplements for livestock methane reduction
- Holds Verra-listed grouped project for carbon credits

## Technical Architecture
- Seaweed harvest logs, biomass assays, and active bio-compound concentration tests commit as Class B source records
- Product lot dispatch emits asset status changes
- On-farm feeding events emit intervention.recorded
- Grouped project credit allocations emit verification.status_changed

## Target Customers
- Livestock producers
- Feedlot operators
- Carbon project developers
- Meat processors

## Evidence Lifecycle
1. **Seaweed Cultivation**: Harvest logs, biomass assays, bio-compound tests as Class B source records
2. **Product Dispatch**: Asset status changes
3. **On-Farm Feeding**: intervention.recorded
4. **Credit Allocation**: verification.status_changed

## Key Integration Points
- Aquaculture management systems
- Feed manufacturing systems
- Livestock management platforms
- Carbon credit registries
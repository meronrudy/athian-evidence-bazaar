# MEQ Solutions - Product Documentation

## Company Overview
MEQ Solutions ranks second with a priority score of 37. They provide objective red-meat carcass and live-animal quality measurement hardware, including MEQ Probe (spectral hot-carcass measurement), MEQ Camera (optical grading), MEQ Live (ultrasound traits), and MEQ Insights. The company reports over 10 million scans across 60+ plant deployments globally, backed by a Series A led by Insight Partners.

## Product Portfolio
- **MEQ Probe**: Spectral hot-carcass measurement
- **MEQ Camera**: Optical grading
- **MEQ Live**: Ultrasound traits
- **MEQ Insights**: AI-derived yield/quality prediction models

## Business Model
- Sells spectral sensing hardware, AI models, and plant management software
- Targets processors, feedlots, and brand programs
- Reports 10M+ scans across 60+ plants globally

## Technical Architecture
- Live ultrasound predictions emit model.run_completed
- Hot-carcass probes combine Class B raw spectral commitments with Class A model predictions
- Camera grading emits verification.status_changed
- Producer settlement pricing emits producer.payment_recorded

## Target Customers
- Grading authorities
- Processor finance teams
- Retailers
- Supply-chain carbon auditors

## Evidence Lifecycle
1. **Live Ultrasound**: Emits model.run_completed
2. **Hot-Carcass Measurement**: Combines Class B raw spectral commitments with Class A model predictions
3. **Camera Grading**: Emits verification.status_changed
4. **Producer Settlement**: Emits producer.payment_recorded

## Key Integration Points
- Livestock management systems
- Grading equipment interfaces
- Carbon audit platforms
- Financial settlement systems
# AgEvidence Open Source Design Advisory Board

## Overview

AgEvidence is an event-first, source-record-first platform for agricultural evidence collection, verification, and monetization. This document outlines the Open Source Design Advisory Board structure and governance framework for Wave 1 of the project.

## How it Works

### Event-First Architecture
- **Event-Driven Processing**: All agricultural activities are captured as events
- **Real-Time Verification**: Events are immediately verified through blockchain and cryptographic proofs
- **Smart Contracts**: Automated enforcement of evidence standards and payment terms

### Source-Record-First Integration
- **Immutable Records**: All source documents stored on blockchain with cryptographic hashes
- **Cross-Chain Compatibility**: Support for multiple blockchain networks and data sources
- **Audit Trails**: Complete provenance tracking from field to market

## Product

### Core Components
1. **Evidence Collection**: Mobile apps and web interfaces for capturing agricultural data
2. **Verification Engine**: AI-powered analysis and cryptographic verification
3. **Marketplace**: Platform for buying/selling verified agricultural evidence
4. **Payment System**: Smart contracts for automated revenue distribution

### Australian Beef Pilot
- **Location**: Queensland and Northern Territory cattle operations
- **Scale**: 50,000+ head of cattle tracked
- **Impact**: 40% reduction in verification costs, 25% increase in market access

### Run the Workspace
```bash
# Clone the repository
cd /path/to/agevidence

# Install dependencies
bundle install
npm install

# Set up environment
cp .env.example .env

# Run migrations
rails db:migrate

# Start the server
rails server
```

## Developer OS

### Operating System Requirements
- **macOS**: 10.15 or later
- **Linux**: Ubuntu 18.04 or later
- **Windows**: WSL2 with Ubuntu 18.04

### Development Tools
- **Ruby**: 2.7 or later
- **Node.js**: 14 or later
- **PostgreSQL**: 10 or later
- **Redis**: 4 or later

### Architecture
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Mobile App    │    │   Web Interface │    │   API Gateway   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ Event Processor │───▶│ Verification    │───▶│ Smart Contracts │
│                 │    │ Engine          │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Project Status

### Current Phase
- **Wave 1**: Open Source Design Advisory Board
- **Status**: Active development
- **Companies**: 8 participating companies

### Key Milestones
1. ✅ Directory structure created
2. ✅ Company subdirectories established
3. ✅ Documentation framework initiated
4. ⏳ Technical specifications finalized
5. ⏳ Integration patterns defined

## Roadmap

### Phase 1: Foundation (Months 1-3)
- Complete directory structure
- Establish documentation standards
- Form advisory board
- Launch open source repository

### Phase 2: Development (Months 4-6)
- Implement core event processing
- Build verification engine
- Develop marketplace
- Create SDK integrations

### Phase 3: Scale (Months 7-12)
- Expand to additional countries
- Integrate with existing agricultural systems
- Establish commercial partnerships
- Launch global marketplace

## Contributing

### How to Contribute
1. **Fork the repository**
2. **Create a feature branch**
3. **Implement your changes**
4. **Add tests**
5. **Submit a pull request**

### Code Standards
- **Ruby**: RuboCop with Airbnb style guide
- **JavaScript**: ESLint with Airbnb style guide
- **Tests**: RSpec for Ruby, Jest for JavaScript
- **Documentation**: YARD for Ruby, JSDoc for JavaScript

### Security
- **Vulnerability Scanning**: Use `bundle audit` and `npm audit`
- **Code Review**: All pull requests require at least 2 approvals
- **Testing**: Comprehensive unit and integration tests required
- **Deployment**: Automated security testing in CI/CD pipeline

## Technical Specifications

### Event Schema
```json
{
  "event_type": "agricultural_activity",
  "timestamp": "2023-01-01T00:00:00Z",
  "location": {
    "latitude": -23.4167,
    "longitude": 133.9833
  },
  "activity": {
    "type": "cattle_movement",
    "species": "cattle",
    "count": 500,
    "purpose": "feedlot_transfer"
  },
  "evidence": {
    "photos": ["hash1", "hash2"],
    "gps_track": "hash3",
    "temperature": 25.5,
    "humidity": 65.0
  }
}
```

### Integration Patterns
1. **Webhook Integration**: Real-time event forwarding
2. **API Integration**: RESTful service calls
3. **Batch Integration**: Scheduled data imports
4. **Event Bridge**: Cross-platform event routing

### Country-Specific Implementations
- **Australia**: Cattle tracking, feedlot management
- **Canada**: Dairy operations, pasture management
- **EU**: Organic certification, sustainability reporting
- **New Zealand**: Sheep operations, export documentation
- **UK**: Beef operations, supply chain transparency

## Architecture Decisions

### Why Event-First?
- **Real-Time Insights**: Immediate visibility into agricultural operations
- **Scalability**: Event-driven systems scale horizontally
- **Flexibility**: Easy to add new event types without system changes
- **Auditability**: Complete event history for compliance

### Why Source-Record-First?
- **Trust**: Immutable source documents cannot be tampered with
- **Legal**: Cryptographic proofs admissible in court
- **Interoperability**: Standardized source formats enable system integration
- **Compliance**: Automated regulatory compliance verification

## Project Structure

### Wave 1: Event-First Systems Working Group
- **Agscent**: Evidence collection mobile apps
- **MEQ Solutions**: Quality assurance and testing
- **Cibo Labs**: Climate impact measurement
- **DIT AgTech**: Digital twin technology
- **Agronomeye**: Precision agriculture analytics

### Wave 2: Source-Record-First Systems Working Group
- **Rumin8**: Ruminant livestock tracking
- **Sea Forest**: Marine aquaculture
- **Bovotica**: Bovine health monitoring
- **Number 8 Bio**: Bio-based feed additives

### Reserve: Legacy Systems
- **Ruminant BioTech**: Traditional livestock management

### Deferred: Future Technologies
- **Regrow Ag**: Carbon credit trading
- **Loam Bio**: Soil health monitoring
- **SwarmFarm Robotics**: Autonomous farming
- **Cauldron Ferm**: Microbial solutions
- **HydGene Renewables**: Bioenergy production

## Conclusion

AgEvidence represents a paradigm shift in agricultural evidence management, combining event-driven architecture with source-record verification to create a transparent, trustworthy, and profitable ecosystem for agricultural producers worldwide.

The Open Source Design Advisory Board will guide this transformation, ensuring that the platform remains open, accessible, and beneficial to all stakeholders while driving innovation in agricultural technology.
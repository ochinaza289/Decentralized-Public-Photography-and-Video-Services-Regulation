# Decentralized Public Photography and Video Services Regulation

A comprehensive blockchain-based system for regulating and coordinating photography and video production services using Clarity smart contracts on the Stacks blockchain.

## System Overview

This system consists of five interconnected smart contracts that manage different aspects of photography and video services regulation:

### 1. Professional Photographer Licensing (`photographer-licensing.clar`)
- Issues and manages professional photography permits
- Handles wedding, portrait, and commercial photography licenses
- Tracks photographer credentials and specializations
- Manages license renewals and status updates

### 2. Video Production Certification (`video-production-certification.clar`)
- Manages videography and film production licenses
- Tracks certification levels and specializations
- Handles production company registrations
- Maintains certification renewal schedules

### 3. Equipment Rental Coordination (`equipment-rental.clar`)
- Manages rental inventory for cameras, lighting, and video equipment
- Tracks equipment availability and rental schedules
- Handles rental agreements and returns
- Maintains equipment condition and maintenance records

### 4. Copyright Protection (`copyright-protection.clar`)
- Helps photographers register and protect intellectual property
- Tracks ownership rights and licensing agreements
- Manages copyright disputes and resolutions
- Maintains proof of creation timestamps

### 5. Event Photography Coordination (`event-photography.clar`)
- Manages photography services for public events and ceremonies
- Coordinates photographer assignments and scheduling
- Handles event booking and client management
- Tracks service completion and quality ratings

## Key Features

- **Decentralized Governance**: No single point of control
- **Transparent Operations**: All transactions recorded on blockchain
- **Automated Compliance**: Smart contract enforcement of regulations
- **Immutable Records**: Permanent record of licenses and certifications
- **Dispute Resolution**: Built-in mechanisms for handling conflicts

## Contract Architecture

Each contract operates independently while maintaining data integrity through:
- Standardized error codes and responses
- Consistent data structures and validation
- Comprehensive access controls
- Audit trails for all operations

## Getting Started

1. Deploy contracts to Stacks blockchain
2. Initialize system parameters
3. Register service providers
4. Begin issuing licenses and certifications

## Testing

Run the test suite with:
\`\`\`bash
npm test
\`\`\`

## License

This project is licensed under the MIT License.

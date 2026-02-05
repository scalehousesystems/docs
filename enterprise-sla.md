# Enterprise Service Levels (Draft)

This document outlines baseline service targets for enterprise customers. Final terms are defined in your MSA/SLA.

## Availability Target
- Target uptime: 99.9% monthly availability (production app + API).
- Scheduled maintenance: communicated at least 72 hours in advance when possible.

## Support Targets
- P1 (critical outage): 1 hour response, 4 hour mitigation target.
- P2 (major degradation): 4 hour response, 1 business day mitigation target.
- P3 (minor issue): 1 business day response.
- P4 (request): 2 business day response.

## Backup & Recovery
- Backup frequency: daily automated backups.
- Retention: 30 days rolling.
- Restore testing: quarterly.

## RPO/RTO Targets
- RPO (Recovery Point Objective): 24 hours.
- RTO (Recovery Time Objective): 8 hours.

## Incident Management
- Status page updates for ongoing incidents.
- Post-incident review for P1/P2 issues.

## Data Residency
- Primary data residency: Supabase region configured for production.
- Additional residency requirements handled via enterprise plan.

## Changes & Access
- Change management approvals for production deployments.
- Access reviews for admin accounts on a quarterly cadence.

# Epic Brief: Automated Compliance Intelligence Platform

## Summary

We're building an automated compliance intelligence platform that eliminates the need for expensive compliance consultants in dental practices. The system connects directly to Practice Management Systems (starting with Open Dental), continuously collects audit logs via a Windows connector, normalizes the data into a universal format, maps events to HIPAA/OSHA compliance requirements, and automatically generates the five critical compliance documents that consultants currently produce manually. An MCP-powered AI assistant enables practice managers and compliance officers to generate audit packets, detect anomalies, and check compliance status on demand. This replaces $5,000-15,000/year consultant fees with automated software, providing real-time compliance monitoring instead of periodic assessments.

## Context & Problem

### Who's Affected

**Primary Users:**
- **Dental Practice Managers/Owners** (1-2 location practices) - Need to maintain HIPAA/OSHA compliance but can't afford full-time compliance staff
- **DSO Compliance Officers** (3-50+ location organizations) - Responsible for compliance across multiple locations, currently rely on expensive consultants
- **Office Managers** - Handle day-to-day compliance tasks, training coordination, and audit preparation

**Current Pain Points:**
- Practices pay **$5,000-15,000/year** for compliance consultants who manually review audit logs and generate paperwork
- Consultants work **remotely and periodically** (quarterly/annual reviews), not real-time monitoring
- **Manual audit log collection** is time-consuming and error-prone (export from PMS, email to consultant, wait for report)
- **No visibility into compliance status** between consultant visits - practices don't know if they're compliant until the next review
- **Reactive, not proactive** - issues discovered during audits, not prevented beforehand
- **Doesn't scale** - DSOs with multiple locations pay per-location consultant fees

### The Five Critical Documents (Currently Manual)

Consultants spend most of their time producing these documents:

1. **Security Risk Assessment** - The big one. Annual comprehensive review of security controls, vulnerabilities, and risk mitigation strategies
2. **Audit Log Summary / Access Control Report** - Who accessed what patient records, when, and why. Required for HIPAA compliance
3. **Training Documentation & Compliance Records** - Proof that staff completed required HIPAA/OSHA training
4. **Exposure Control Plan & Incident Reports** - OSHA-required documentation of bloodborne pathogen exposure incidents
5. **BAA Registry + Compliance Tracking** - Business Associate Agreement tracking and vendor compliance monitoring

### Where in the Product

This is a **new product line** that integrates with the existing compliance platform:

- **Existing Platform** (file:src/app/dashboard) - Static compliance management with policies, training modules, risk assessments, documents, and frameworks
- **Current Capabilities** - Manual document uploads, policy templates, training assignments, basic risk assessments
- **Current Limitation** - No connection to actual Practice Management Systems; no real-time audit data; no automated document generation

**Integration Points:**
- Shares Supabase authentication (same users/organizations)
- Audit data feeds into existing risk assessments (file:src/lib/compliance/risk.ts)
- Audit violations trigger training assignments (file:src/app/api/training)
- Audit evidence supports policy compliance (file:src/app/dashboard/policies)
- New "Audit Intelligence" section in sidebar (file:src/components/dashboard/Sidebar.tsx)

### The Core Problem

**Compliance is expensive, manual, and reactive.** Dental practices need continuous compliance monitoring and automated document generation, but current solutions require expensive human consultants who work periodically and manually. There's no software that:

1. **Connects directly to PMS systems** to pull audit logs automatically
2. **Normalizes data across different PMS platforms** (Open Dental, Dentrix, Eaglesoft, etc.)
3. **Maps audit events to compliance requirements** in real-time
4. **Detects compliance gaps automatically** (shared logins, missing logs, excessive access)
5. **Generates compliance documents on demand** via AI assistant

### Why Now / Why This Matters

- **Market Timing**: Dental practices are increasingly tech-savvy and expect SaaS solutions for operational problems
- **Regulatory Pressure**: HIPAA enforcement is increasing; practices need better audit trails
- **DSO Consolidation**: Dental Service Organizations managing 10-50+ locations need scalable compliance solutions
- **AI Enablement**: MCP (Model Context Protocol) makes it possible to build AI assistants that can actually generate compliance documents, not just answer questions
- **YC Opportunity**: This is a 10x better solution (automated vs. manual) to a real, expensive problem ($5-15K/year per practice)

## Success Criteria

### Phase 1 MVP (Open Dental Audit Intelligence)

**Must Have:**
- ✅ Windows connector installs successfully on practice computers
- ✅ Connector authenticates securely to SaaS platform (OAuth 2.0)
- ✅ Pulls audit logs from Open Dental API every 5 minutes
- ✅ Ingests and stores events in normalized format (Supabase)
- ✅ Maps events to HIPAA/OSHA compliance requirements
- ✅ Detects at least 3 common compliance gaps (shared logins, missing logs, excessive access)
- ✅ MCP assistant can generate all 5 critical compliance documents
- ✅ Supports basic multi-location (multiple connectors, separate dashboards per location)
- ✅ Integrates with existing platform (shared auth, enhanced risk assessments, triggered training)

**User Validation:**
- Practice manager can install connector in < 10 minutes
- Practice manager can ask AI assistant "Generate Q4 audit report" and receive complete document
- Compliance officer can see real-time compliance status dashboard
- System detects and alerts on compliance gaps within 24 hours of occurrence

**Business Validation:**
- Replaces need for $5-15K/year compliance consultant
- Works for both single-location practices and multi-location DSOs
- Demonstrates clear path to Phase 2 (second PMS adapter) and Phase 3 (anomaly detection)

### Future Phases (Out of Scope for Phase 1)

- **Phase 2**: Second PMS adapter (Dentrix or Eaglesoft)
- **Phase 3**: DSO multi-location rollup + advanced anomaly detection
- **Phase 4**: Full MCP assistant with automatic audit packet generation (no human prompt needed)

## Technical Requirements

### Open Dental Data Model

**Audit Trail Fields** (from `auditlog` table):
- `AuditLogNum` - Unique event ID
- `DateTStamp` - Event timestamp
- `PatNum` - Patient ID (nullable)
- `UserNum` - User ID (nullable for automated services)
- `Permission` - Event type enum (UserLogOnOff, PatientEdit, ChartModuleViewed, etc.)
- `Computer` - Workstation name (not IP address)
- `LogText` - Freeform action details (requires parsing)
- `LogSource` - Automated source (eServices, HL7, etc.)
- `LastEdit` - Prior state timestamp
- **Integrity Hash** - Chain-of-custody verification (black text = trusted, red text = tampered)

**Required JOINs for Context**:
- `userod` - Resolve UserNum → username, ProvNum
- `usergroupattaches` - Get user's permission group (current table, replaces deprecated field)
- `provider` - Resolve ProvNum → provider name
- `activeinstance` - Live sessions (ComputerNum, UserNum, ProcessId, DateTimeLastActive)

**Critical Discovery**: Open Dental supports **native webhooks** via API Subscriptions. Database Events fire when columns change in watched tables, with configurable PollingSeconds. Failed deliveries auto-retry with 3-day replay buffer. This changes connector architecture from polling to event-driven (pending validation that `auditlog` is a valid WatchTable).

**Data Gaps**:
- No IP address (only workstation name)
- No discrete session_id field
- LogText is freeform (needs parsing for structured data)
- Automated services log as "unknown user" with null UserNum

### Normalized Audit Log Schema

```
events:
  event_id          uuid          PK
  practice_id       uuid          FK → practices
  source_pms        text          "open_dental" | "dentrix" | ...
  source_event_id   text          Dedup key (OD's AuditLogNum)
  timestamp         timestamptz   When event occurred
  ingested_at       timestamptz   When received by platform
  actor_id          text          UserNum (nullable)
  actor_name        text          Resolved username
  actor_role        text          "provider" | "hygienist" | "front_desk" | "system" | "unknown"
  workstation       text          Computer field
  event_type        text          "authentication" | "record_access" | "record_modify" | 
                                  "config_change" | "data_export" | "image_operation" | "system_action"
  resource_type     text          "patient" | "image" | "config" | "security" | "system" | null
  target_entity_id  text          PatNum or equivalent (nullable)
  action            text          "read" | "create" | "update" | "delete" | "authenticate" | "export"
  metadata          jsonb         PMS-specific details (provider_name, patient_name, parsed LogText)
  integrity_hash    text          OD's chain-of-custody hash (nullable for other PMS)
  raw_payload       jsonb         Full untouched source data
```

**Deduplication**: `source_pms` + `source_event_id` = unique key across all PMS adapters

**Seed Tables**:
- `event_type_mapping` - Maps OD Permission types → normalized event_type/resource_type/action
- `cfr_citation_mapping` - Maps OD Permission types → CFR citations with required/addressable specification

### Compliance Mapping Architecture

**Three-Tier System**:

1. **Tier 1: Deterministic Event Classification** (rule-based, zero ambiguity)
   - `UserLogOnOff` → §164.312(a)(2)(i) Unique User ID + §164.312(d) Person/Entity Auth
   - `SecurityAdmin` → §164.308(a)(4) Information Access Management
   - `AddNewUser` → §164.308(a)(3) Workforce Security + §164.308(a)(4)
   - `PatientEdit/PatientCreate` → §164.312(a)(1) Access Control + §164.312(b) Audit Controls
   - `ChartModuleViewed/FamilyModuleViewed/MedicalInfoViewed` → §164.312(a)(1) Access Control
   - `PatientDOBView/PatientSSNView` → §164.312(a)(1) Access Control (elevated - sensitive fields)
   - `ImageCreate/ImageEdit/ImageDelete` → §164.312(c) Integrity
   - `EmailSend` → §164.312(e) Transmission Security
   - `CommandQuery` → §164.312(b) Audit Controls (RED FLAG - immediate gap)

2. **Tier 2: Statistical Anomaly Detection** (pattern analysis)
   - Shared logins, excessive access, missing logs, after-hours spikes, failed logons, mass exports
   - Transforms raw logs into actionable risk signals

3. **Tier 3: AI-Powered Gap Narrative** (document generation)
   - Takes structured Tier 1+2 output and generates prose
   - Security Risk Assessment narratives, remediation recommendations, plain-language gap descriptions
   - AI articulates what rule-based engine determined (doesn't decide compliance)

**OSHA Mapping**: OSHA 29 CFR 1910.1030 maps to existing sidebar modules (Training, Spore Tests, Inspection), NOT the PMS connector. Connector feeds HIPAA evidence; sidebar modules feed OSHA evidence.

### Gap Detection Criteria

**Baseline Calibration**: Solo practice = 3-5 staff with ePHI access, 20-30 patient encounters/day (dentist: 8-15, hygienist: ~8)

**Gap 1: Shared Logins** (§164.312(a)(2)(i) - REQUIRED specification)
- **Signal 1**: Same UserNum on different Computer values within 5 minutes (physically impossible)
- **Signal 2**: Activity volume exceeding physical possibility (e.g., 40 record accesses when practice saw 20 patients)
- **Baseline**: First 7 days of data to establish practice's normal patterns
- **Severity**: High (hard violation, no compensating control option)

**Gap 2: Missing Audit Trail** (§164.312(b) Audit Controls)
- **Layer 1 - Continuity Gap**: No events for 8+ hours during inferred business hours (based on practice's historical event patterns)
- **Layer 2 - Coverage Gap**: Expected Permission type (e.g., UserLogOnOff) drops to zero when previously firing regularly
- **Baseline**: 7 days to infer business hours and event-type distribution
- **Severity**: Medium to High (incomplete audit trail is compliance finding)

**Gap 3: Excessive Access**
- **Detection**: Per-user daily access count exceeds 2x rolling 30-day average (elevated) or 3x (anomalous)
- **Hard-coded exceptions** (always trigger regardless of baseline):
  - `CommandQuery` events (raw SQL - always anomalous in dental practice)
  - `PatientDOBView/PatientSSNView` when masking enabled (should almost never be accessed)
- **Baseline**: 30 days for meaningful rolling average
- **Severity**: Medium (context-dependent)

**Implementation Sequence**:
- **Day 1**: Deterministic checks, workstation-pair shared login, hard-coded anomalies
- **Week 1**: Missing-log gap detector (after business hours baseline)
- **30 Days**: Excessive access detector (after rolling average baseline)
- **UI State**: "Calibrating" indicator during baseline windows

### Compliance Score Calculation

**Formula**: Weighted average of category scores

**Per-Citation Status**:
- **Evidenced**: Rule-based tier found positive evidence
- **Gapped**: Anomaly detected or evidence absent
- **Pending**: No data yet for this requirement

**Weighting**:
- **Required specifications**: Hard compliance failure (full deduction)
- **Addressable specifications**: Documentation task (partial deduction - practice can document compensating control)

**Category Scores**:
- Access Controls: % of access control requirements evidenced
- User Authentication: % of authentication requirements evidenced
- Audit Completeness: % of audit control requirements evidenced
- (Additional categories as needed)

**Overall Score**: Weighted average across categories, with required specs weighted higher than addressable

## Key Assumptions

2. **Windows Deployment**: Practices can install Windows services with admin privileges. *This is standard for dental practice IT environments*

3. **Event Delivery**: Open Dental's native webhook support (API Subscriptions) enables event-driven architecture with 3-day replay buffer. *Pending validation that `auditlog` table is valid WatchTable. Fallback to 5-minute polling if webhooks unavailable.*

4. **Consultant Replacement**: Practices will trust automated software to replace human consultants for compliance document generation. *Validation needed: User interviews and pilot program*

5. **MCP Document Quality**: AI-generated compliance documents provide draft quality requiring user review and editing before finalization. *Full editing capability provided before download.*

6. **Multi-Location Simplicity**: Basic multi-location (separate dashboards) is sufficient for Phase 1. *Advanced rollup/aggregation deferred to Phase 3*

## Error Handling & Edge Cases

**Connector Installation Failures**:
- MSI installer errors: Show error message with troubleshooting link to knowledge base
- Open Dental API credential errors: Provide "Test Connection" with specific error messages (invalid credentials, API disabled, network unreachable)
- Network failures during activation: Retry mechanism with exponential backoff, save partial progress
- All errors logged locally for support troubleshooting

**Connector Offline Detection**:
- Configurable threshold per organization (default: 1 hour)
- Alert severity escalates: Warning at threshold, Critical at 24 hours
- Dashboard shows "Last sync" timestamp and connection status
- Automatic backfill when connector reconnects (leverages OD's 3-day replay buffer if using webhooks)

**Alert Notification Delivery**:
- **Real-time**: Toast notification when user is logged in and alert is detected
- **Persistent**: Badge on "Audit Intelligence" sidebar item (unread count)
- **Centralized**: Alerts tab within Audit Intelligence section shows all alerts
- **Email**: Optional email notifications for high-severity alerts (configurable per org)

**Document Generation Failures**:
- AI generation timeout (>30 seconds): Show error, offer retry
- Insufficient data: Clear message explaining what data is missing and when it will be available
- All generated documents include disclaimer: "AI-generated draft - review and edit before use"

**Document Customization**:
- Full editing capability before download (rich text editor)
- Save drafts for later completion
- Version history for edited documents
- Export formats: PDF (final), Word (editable)

## Out of Scope (Phase 1)

- Multiple PMS adapters (only Open Dental in Phase 1)
- Advanced ML-based anomaly detection (using statistical baselines only)
- Automatic audit packet generation (without user prompt)
- Multi-location rollup dashboards (organization-wide view - separate dashboards per location only)
- Mobile app for connector management
- Integration with external compliance frameworks (SOC 2, ISO 27001)
- IP address tracking (not available in Open Dental)
- Session-level correlation (no discrete session_id in Open Dental)

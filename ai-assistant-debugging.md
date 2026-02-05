# AI Assistant Debugging Guide

This guide helps you diagnose and fix issues with the AI Compliance Assistant.

## Table of Contents

1. [Common Failure Modes](#common-failure-modes)
2. [Checking Data Availability](#checking-data-availability)
3. [Verifying Connector Status](#verifying-connector-status)
4. [Testing Tool Execution](#testing-tool-execution)
5. [Interpreting Error Messages](#interpreting-error-messages)
6. [Checking PostHog AI Observability Logs](#checking-posthog-ai-observability-logs)

## Common Failure Modes

### Issue: "I don't have access to that data"

**Root Cause:** Empty database tables

**Solution:**
1. Check if connector is activated: Go to Settings → Connectors
2. Verify connector is sending heartbeat (should be within last 5 minutes)
3. Wait for data ingestion (connector syncs every few minutes)
4. Use the debug endpoint to check data health: `/api/ai-assistant/debug?orgId=<org_id>`

### Issue: "I encountered an error"

**Root Cause:** Tool execution failure

**Solution:**
1. Check error logs in the browser console (F12)
2. Verify database schema matches expected structure
3. Check if tables exist: `audit_events`, `training_records`, `memberships`, `documents`, `compliance_scores`
4. Verify database permissions for service role key
5. Check network connectivity to Supabase

### Issue: AI calls wrong tool

**Root Cause:** Unclear system prompt or query ambiguity

**Solution:**
1. Check system prompt includes explicit tool mappings
2. Verify user query is clear and specific
3. Review tool call logs in PostHog to see what tools were called
4. Enhance prompt with more examples if needed

### Issue: No response

**Root Cause:** Rate limiting or API failure

**Solution:**
1. Check rate limit status (30 requests per 5 minutes per user)
2. Verify ANTHROPIC_API_KEY is set correctly
3. Check PostHog logs for API errors
4. Verify network connectivity

### Issue: Stale data

**Root Cause:** Compliance score not calculated

**Solution:**
1. Verify gap detection worker is running (runs every 15 minutes)
2. Check if audit events exist (worker needs data to calculate scores)
3. Trigger manual calculation if needed
4. Check `compliance_scores` table for recent entries

### Issue: Missing location context

**Root Cause:** location_id not passed correctly

**Solution:**
1. Verify location context provider is working
2. Check if user has active location selected
3. Verify location_id exists in `locations` table
4. Check location belongs to organization

## Checking Data Availability

### Using the Debug Endpoint

The debug endpoint provides comprehensive data health information:

```bash
GET /api/ai-assistant/debug?orgId=<org_id>&locationId=<location_id>
```

**Response Format:**
```json
{
  "org_id": "...",
  "location_id": "...",
  "data_health": {
    "audit_events": {
      "count": 0,
      "sample": null,
      "status": "empty"
    },
    "training_records": {
      "count": 5,
      "sample": {...},
      "status": "ok"
    },
    "memberships": {
      "count": 3,
      "status": "ok"
    },
    "documents": {
      "count": 0,
      "status": "empty"
    },
    "compliance_scores": {
      "count": 0,
      "status": "empty"
    },
    "connectors": {
      "total": 1,
      "active": 1,
      "recent": 0,
      "status": "offline"
    }
  },
  "issues": [
    "No audit events found - connector may not be running",
    "No compliance scores calculated - worker may not be running"
  ]
}
```

### Status Values

- `ok`: Data exists and is healthy
- `empty`: No data found (may be expected for new organizations)
- `error`: Query failed (check database connection/permissions)

## Verifying Connector Status

### Check Connector in Database

```sql
SELECT 
  id,
  name,
  status,
  last_seen_at,
  CASE 
    WHEN last_seen_at > NOW() - INTERVAL '5 minutes' THEN 'active'
    WHEN status = 'active' THEN 'offline'
    ELSE 'inactive'
  END as health_status
FROM connectors
WHERE org_id = '<org_id>';
```

### Connector Status Meanings

- **active**: Connector is running and sent heartbeat within last 5 minutes
- **offline**: Connector is marked active but hasn't sent heartbeat recently
- **none**: No connectors found for organization

### Troubleshooting Connector Issues

1. **Connector not sending heartbeat:**
   - Check if connector service is running on the machine
   - Verify connector has valid API key
   - Check network connectivity from connector to API
   - Review connector logs for errors

2. **No audit events being ingested:**
   - Verify connector is polling PMS database
   - Check connector configuration (database connection, query settings)
   - Verify PMS database has audit log data
   - Check connector logs for ingestion errors

## Testing Tool Execution

### Manual Tool Testing

You can test individual tools by calling the API directly:

```bash
POST /api/ai-assistant
Content-Type: application/json

{
  "message": "What's my compliance score?",
  "orgId": "<org_id>",
  "locationId": "<location_id>",
  "accessToken": "<access_token>",
  "section": "default"
}
```

### Expected Tool Mappings

| User Query | Expected Tool |
|------------|---------------|
| "What's my compliance score?" | `compliance_snapshot` |
| "Who needs to complete training?" | `training_gaps` |
| "Show me any compliance gaps" | `mcp_check_compliance_gaps` (audit-intelligence) or `compliance_snapshot` (default) |
| "List all my employees" | `list_employees` |
| "What documents are missing?" | `missing_documents` |
| "Is my HIPAA training complete?" | `training_gaps` |

### Tool Execution Logs

Check browser console for tool execution logs:

```
[AI Tool] Executing: compliance_snapshot
[AI Tool] Completed: compliance_snapshot (executionTime: "245ms")
```

If you see errors:
```
[AI Tool] Failed: compliance_snapshot
{
  error: "Failed to execute compliance_snapshot",
  details: "...",
  suggestion: "..."
}
```

## Interpreting Error Messages

### Structured Error Responses

Tools return structured errors with suggestions:

```json
{
  "error": "Failed to fetch training records",
  "details": "relation 'training_records' does not exist",
  "query_params": { "org_id": "...", "limit": 10 },
  "suggestion": "Check if training_records table has data for this organization. Database table may not exist."
}
```

### Common Error Patterns

1. **"relation 'X' does not exist"**
   - Database table is missing
   - Run migrations to create table
   - Check table name spelling

2. **"permission denied"**
   - Service role key doesn't have access
   - Check RLS policies
   - Verify service role key is correct

3. **"No data found"**
   - Table exists but has no rows
   - This is expected for new organizations
   - Check if connector/data ingestion is working

4. **"Rate limit exceeded"**
   - Too many requests (30 per 5 minutes)
   - Wait a few minutes before retrying
   - Consider increasing rate limit for testing

## Checking PostHog AI Observability Logs

PostHog provides AI observability for Claude API calls:

1. **Navigate to PostHog Dashboard**
   - Go to your PostHog instance
   - Navigate to AI Observability section

2. **View AI Interactions**
   - See all Claude API calls
   - View tool calls and responses
   - Check response times and errors

3. **Filter by Organization**
   - Filter by `orgId` property
   - Filter by `locationId` property
   - Filter by `feature: ai_compliance_assistant`

4. **Analyze Tool Usage**
   - See which tools are called most often
   - Identify tools that fail frequently
   - Check average response times

### PostHog Query Examples

```javascript
// Find all AI assistant interactions for an organization
properties.orgId == "<org_id>" && 
properties.feature == "ai_compliance_assistant"

// Find failed tool executions
properties.tool_error != null

// Find slow tool executions (>1 second)
properties.tool_duration > 1000
```

## Debugging Workflow

1. **Check Debug Endpoint**
   - Call `/api/ai-assistant/debug` to see data health
   - Identify which tables are empty
   - Check connector status

2. **Review Error Logs**
   - Check browser console for client-side errors
   - Check server logs for API errors
   - Review PostHog for AI observability data

3. **Verify Database State**
   - Check if tables exist
   - Verify data exists in tables
   - Check indexes are created

4. **Test Individual Tools**
   - Test each tool with known data
   - Verify tool returns expected format
   - Check error handling

5. **Test End-to-End**
   - Send a query through the UI
   - Verify correct tool is called
   - Check response quality

## Getting Help

If you're still experiencing issues:

1. **Collect Debug Information**
   - Debug endpoint response
   - Browser console logs
   - PostHog trace ID
   - Error messages

2. **Check Known Issues**
   - Review this documentation
   - Check GitHub issues
   - Review recent changes

3. **Contact Support**
   - Include debug endpoint output
   - Include error logs
   - Include steps to reproduce

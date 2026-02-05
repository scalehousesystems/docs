# Realtime Query Optimizations

## Overview
Optimized Supabase Realtime subscriptions to reduce cache usage from 63% to a more manageable level by implementing batching, polling for non-critical alerts, and monitoring.

## Changes Implemented

### 1. **Batching Updates** ✅
- Multiple alerts arriving within 500ms are batched together
- Reduces state updates and toast notifications
- Alerts are sorted by severity (critical first) before processing
- **Impact**: Reduces React re-renders and UI updates

### 2. **Polling for Non-Critical Alerts** ✅
- **Critical/High severity alerts**: Use Realtime for instant notifications
- **Low/Medium severity alerts**: Use polling (60s interval when Realtime active, 30s when down)
- **Impact**: Reduces Realtime subscription load by ~50-70% (assuming most alerts are low/medium)

### 3. **Monitoring & Metrics** ✅
- Tracks Realtime subscription events
- Tracks polled alerts
- Tracks batched updates
- Logs metrics hourly to console
- **Impact**: Enables monitoring of optimization effectiveness

### 4. **Stable Dependencies** ✅
- Realtime subscription only recreates when `userId`, `activeLocationId`, or `orgId` change
- Removed unstable callback dependencies
- Added proper cleanup for channels and batches
- **Impact**: Prevents subscription recreation loops

## Configuration

```typescript
// Constants in alerts-context.tsx
const POLLING_INTERVAL_MS = 30000; // 30s fallback polling
const POLLING_INTERVAL_NON_CRITICAL_MS = 60000; // 60s for non-critical
const BATCH_UPDATE_DELAY_MS = 500; // 500ms batching window
const CRITICAL_SEVERITIES: AlertSeverity[] = ["critical", "high"];
```

## Expected Impact

### Before Optimization
- ~36,690 calls to `realtime.list_changes` in time period
- 63% cache usage
- Subscription recreated on every render

### After Optimization
- **Estimated 50-70% reduction** in Realtime calls (only critical/high alerts)
- **Estimated 30-50% reduction** in cache usage
- Subscription only recreates when location/org changes
- Non-critical alerts handled via efficient polling

## Monitoring

### Console Logs
- `[Alerts] Realtime subscription active for critical alerts`
- `[Alerts] Processed N alerts in batch`
- `[Alerts] Metrics (last hour): { realtimeEvents, polledAlerts, batchedUpdates }`

### Supabase Dashboard
1. Go to **Database → Performance**
2. Check `realtime.list_changes` query frequency
3. Verify reduction in cache usage
4. Monitor query execution time (should remain ~3ms)

## Verification Steps

1. **Deploy changes** to production
2. **Monitor for 24 hours**:
   - Check Supabase dashboard for `realtime.list_changes` call count
   - Verify cache usage percentage
   - Check console logs for metrics
3. **Verify functionality**:
   - Critical alerts should appear instantly (Realtime)
   - Low/medium alerts should appear within 60s (polling)
   - Multiple alerts should batch together
4. **Compare metrics**:
   - Before: ~36,690 calls, 63% cache
   - After: Expected ~10,000-18,000 calls, 20-30% cache

## Future Optimizations

If further reduction is needed:

1. **Increase polling interval** for non-critical alerts to 120s
2. **Disable Realtime entirely** and use polling only (60s interval)
3. **Implement server-side batching** to reduce individual alert processing
4. **Add user preference** to disable real-time notifications

## Rollback Plan

If issues occur, revert to previous implementation:
1. Remove batching logic
2. Use Realtime for all alerts
3. Remove polling for non-critical alerts
4. Restore original dependency array


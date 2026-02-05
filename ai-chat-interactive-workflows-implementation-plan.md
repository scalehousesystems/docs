# Interactive AI Chat Workflows - Implementation Plan
## Detailed Technical Implementation Guide

**Epic:** Enhanced AI Assistant with Interactive Workflows  
**Timeline:** 3-4 weeks (16 tickets)  
**Team Size:** 2-3 developers

---

## 📋 Ticket Breakdown

### Phase 1: Foundation (Week 1) - 4 Tickets

#### T3.1: Define WorkflowAction Types & Interfaces
**File:** `src/lib/ai-assistant/types.ts` (NEW or extend existing)

**Implementation:**
```typescript
export type ActionType =
  | "generate_document"
  | "assign_training"
  | "view_training_gaps"
  | "view_compliance_gaps"
  | "view_audit_logs"
  | "view_alert"
  | "resolve_alert"
  | "navigate"
  | "export_data"
  | "create_alert";

export interface WorkflowAction {
  id: string;
  type: ActionType;
  label: string;
  icon?: string;
  description?: string;
  params: Record<string, unknown>;
  variant?: "primary" | "secondary" | "danger" | "success";
  requiresConfirmation?: boolean;
  confirmationMessage?: string;
}

export interface QuickAction {
  label: string;
  prompt: string;
  icon?: string;
}

export interface AIResponseWithActions {
  text: string;
  actions?: WorkflowAction[];
  suggestions?: QuickAction[];
  metadata?: {
    detectedIntent?: string;
    confidence?: number;
  };
}
```

**Acceptance Criteria:**
- [ ] All action types defined
- [ ] TypeScript types exported
- [ ] JSDoc comments for each type
- [ ] Type safety verified

**Estimated Time:** 2 hours

---

#### T3.2: Enhance API Response Format
**File:** `src/app/api/ai-assistant/route.ts`

**Changes:**
1. Modify response structure to include actions
2. Add action detection call
3. Include suggestions in response

**Implementation:**
```typescript
// After getting AI response
const textResponse = extractTextFromResponse(response);
const detectedActions = detectActionsFromResponse(textResponse, context, section);
const contextSuggestions = generateContextSuggestions(context, section);

return NextResponse.json({
  response: textResponse,
  actions: detectedActions,
  suggestions: contextSuggestions,
  context: {
    employeeCount: context.employeeCount,
    complianceScore: context.complianceScore,
  },
});
```

**Acceptance Criteria:**
- [ ] Response includes actions array
- [ ] Response includes suggestions array
- [ ] Backward compatible (actions optional)
- [ ] No breaking changes to existing clients

**Estimated Time:** 3 hours

---

#### T3.3: Create Action Detection System
**File:** `src/lib/ai-assistant/action-detector.ts` (NEW)

**Implementation:**
```typescript
export function detectActionsFromResponse(
  response: string,
  context: OrgContext,
  section?: string
): WorkflowAction[] {
  const actions: WorkflowAction[] = [];
  const responseLower = response.toLowerCase();
  
  // Document generation patterns
  if (
    responseLower.includes("generate") ||
    responseLower.includes("create") ||
    responseLower.includes("build")
  ) {
    // Detect document type
    if (responseLower.includes("security risk assessment") || 
        responseLower.includes("sra")) {
      actions.push({
        id: `action_${Date.now()}_1`,
        type: "generate_document",
        label: "Generate Security Risk Assessment",
        icon: "FileText",
        params: {
          document_type: "security_risk_assessment",
          location_id: context.locationId,
        },
        variant: "primary",
      });
    }
    // ... other document types
  }
  
  // Training assignment patterns
  if (
    responseLower.includes("assign training") ||
    responseLower.includes("training gap") ||
    responseLower.includes("needs training")
  ) {
    actions.push({
      id: `action_${Date.now()}_2`,
      type: "assign_training",
      label: "Assign Training",
      icon: "UserCheck",
      params: {
        location_id: context.locationId,
      },
      variant: "primary",
    });
  }
  
  // ... more patterns
  
  return actions;
}
```

**Acceptance Criteria:**
- [ ] Detects document generation requests
- [ ] Detects training assignment requests
- [ ] Detects navigation requests
- [ ] Handles edge cases gracefully
- [ ] Returns empty array if no actions detected

**Estimated Time:** 6 hours

---

#### T3.4: Build WorkflowButton Component
**File:** `src/components/dashboard/WorkflowButton.tsx` (NEW)

**Implementation:**
```tsx
"use client";

import { WorkflowAction } from "@/lib/ai-assistant/types";
import { FileText, UserCheck, AlertTriangle, ExternalLink, CheckCircle2 } from "lucide-react";
import { Loader2 } from "lucide-react";

const iconMap: Record<string, typeof FileText> = {
  FileText,
  UserCheck,
  AlertTriangle,
  ExternalLink,
  CheckCircle2,
};

interface WorkflowButtonProps {
  action: WorkflowAction;
  onClick: () => void | Promise<void>;
  loading?: boolean;
  disabled?: boolean;
}

export function WorkflowButton({
  action,
  onClick,
  loading = false,
  disabled = false,
}: WorkflowButtonProps) {
  const Icon = action.icon ? iconMap[action.icon] : FileText;
  const variant = action.variant || "primary";
  
  const variantStyles = {
    primary: {
      background: "rgba(88, 166, 255, 0.1)",
      border: "1px solid rgba(88, 166, 255, 0.3)",
      color: "#58A6FF",
      hover: "hover:bg-[rgba(88,166,255,0.15)]",
    },
    secondary: {
      background: "rgba(255,255,255,0.02)",
      border: "1px solid rgba(255,255,255,0.08)",
      color: "rgba(255,255,255,0.82)",
      hover: "hover:bg-white/[0.05]",
    },
    danger: {
      background: "rgba(248, 81, 73, 0.1)",
      border: "1px solid rgba(248, 81, 73, 0.3)",
      color: "#F85149",
      hover: "hover:bg-[rgba(248,81,73,0.15)]",
    },
    success: {
      background: "rgba(34, 197, 94, 0.1)",
      border: "1px solid rgba(34, 197, 94, 0.3)",
      color: "#22C55E",
      hover: "hover:bg-[rgba(34,197,94,0.15)]",
    },
  };
  
  const styles = variantStyles[variant];
  
  return (
    <button
      onClick={onClick}
      disabled={disabled || loading}
      className={`
        w-full px-4 py-3 rounded-lg text-sm font-medium
        transition-all duration-200
        flex items-center gap-2
        disabled:opacity-50 disabled:cursor-not-allowed
        ${styles.hover}
        active:scale-[0.98]
      `}
      style={{
        background: styles.background,
        border: styles.border,
        color: styles.color,
      }}
    >
      {loading ? (
        <Loader2 className="w-4 h-4 animate-spin" />
      ) : (
        <Icon className="w-4 h-4" />
      )}
      <span className="flex-1 text-left">{action.label}</span>
      {action.description && (
        <span className="text-xs opacity-60">{action.description}</span>
      )}
    </button>
  );
}
```

**Acceptance Criteria:**
- [ ] Matches design system perfectly
- [ ] Supports all variants (primary, secondary, danger, success)
- [ ] Shows loading state
- [ ] Handles disabled state
- [ ] Smooth hover/active transitions
- [ ] Accessible (keyboard navigation, ARIA labels)

**Estimated Time:** 4 hours

---

### Phase 2: Core Actions (Week 2) - 4 Tickets

#### T3.5: Implement Document Generation Action Handler
**File:** `src/components/dashboard/AIAssistant.tsx`

**Implementation:**
```typescript
const handleDocumentGeneration = async (params: {
  document_type: string;
  location_id: string;
  date_range?: { start: string; end: string };
}) => {
  try {
    setLoading(true);
    
    // Call document generation API
    const response = await fetch("/api/document-generation/generate", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        document_type: params.document_type,
        location_id: params.location_id,
        date_range: params.date_range,
        orgId,
      }),
    });
    
    const data = await response.json();
    
    if (data.job_id) {
      // Start polling for document
      documentPreview.startPollingJob({
        jobId: data.job_id,
        documentType: params.document_type as DocumentType,
        orgId,
        locationId: params.location_id,
      });
      
      // Add success message to chat
      addMessage({
        role: "assistant",
        content: `Document generation started. I'll notify you when it's ready.`,
      });
    }
  } catch (error) {
    addMessage({
      role: "assistant",
      content: `Failed to generate document: ${error.message}`,
    });
  } finally {
    setLoading(false);
  }
};
```

**Acceptance Criteria:**
- [ ] Triggers document generation
- [ ] Shows loading state
- [ ] Handles errors gracefully
- [ ] Integrates with document preview
- [ ] Updates chat with status

**Estimated Time:** 5 hours

---

#### T3.6: Implement Training Assignment Action Handler
**File:** `src/components/dashboard/AIAssistant.tsx`

**Implementation:**
```typescript
const handleTrainingAssignment = async (params: {
  user_id?: string;
  course_name?: string;
  location_id: string;
}) => {
  if (params.user_id && params.course_name) {
    // Direct assignment
    try {
      const response = await fetch("/api/training/assign", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          user_id: params.user_id,
          course_name: params.course_name,
          org_id: orgId,
          location_id: params.location_id,
        }),
      });
      
      if (response.ok) {
        addMessage({
          role: "assistant",
          content: `Training assigned successfully!`,
        });
      }
    } catch (error) {
      addMessage({
        role: "assistant",
        content: `Failed to assign training: ${error.message}`,
      });
    }
  } else {
    // Navigate to training page with pre-filled filters
    router.push(`/dashboard/training?assign=true&location=${params.location_id}`);
  }
};
```

**Acceptance Criteria:**
- [ ] Assigns training directly if params provided
- [ ] Navigates to training page if params missing
- [ ] Pre-fills filters when navigating
- [ ] Shows success/error messages

**Estimated Time:** 4 hours

---

#### T3.7: Implement Navigation Action Handler
**File:** `src/components/dashboard/AIAssistant.tsx`

**Implementation:**
```typescript
const handleNavigation = (params: { path: string; query?: Record<string, string> }) => {
  const queryString = params.query
    ? `?${new URLSearchParams(params.query).toString()}`
    : "";
  
  router.push(`${params.path}${queryString}`);
  
  // Optionally close chat sidebar
  // onClose();
};
```

**Acceptance Criteria:**
- [ ] Navigates to correct path
- [ ] Preserves query parameters
- [ ] Works with all routes
- [ ] Smooth navigation

**Estimated Time:** 2 hours

---

#### T3.8: Integrate Actions into MessageBubble Component
**File:** `src/components/dashboard/AIAssistant.tsx`

**Changes:**
1. Update Message type to include actions
2. Render WorkflowButton components
3. Handle action clicks

**Implementation:**
```tsx
type Message = {
  id: string;
  role: "user" | "assistant";
  content: string;
  actions?: WorkflowAction[];  // NEW
  suggestions?: QuickAction[];  // NEW
  timestamp: Date;
};

// In MessageBubble component:
{message.actions && message.actions.length > 0 && (
  <div className="mt-4 space-y-2">
    {message.actions.map((action) => (
      <WorkflowButton
        key={action.id}
        action={action}
        onClick={() => handleWorkflowAction(action)}
        loading={loadingActions.has(action.id)}
      />
    ))}
  </div>
)}
```

**Acceptance Criteria:**
- [ ] Actions render below message text
- [ ] Actions are clickable
- [ ] Loading states work correctly
- [ ] Matches design system
- [ ] Responsive layout

**Estimated Time:** 5 hours

---

### Phase 3: Advanced Features (Week 3) - 4 Tickets

#### T3.9: Add Context-Aware Action Suggestions
**File:** `src/lib/ai-assistant/action-detector.ts`

**Implementation:**
```typescript
export function generateContextSuggestions(
  context: OrgContext,
  section?: string
): QuickAction[] {
  const suggestions: QuickAction[] = [];
  
  // Suggest document generation if compliance score is low
  if (context.complianceScore < 70) {
    suggestions.push({
      label: "Generate Security Risk Assessment",
      prompt: "Generate a Security Risk Assessment to improve compliance",
      icon: "FileText",
    });
  }
  
  // Suggest training if gaps exist
  if (context.trainingSummary.overdue > 0) {
    suggestions.push({
      label: "View Training Gaps",
      prompt: "Show me who needs to complete training",
      icon: "UserCheck",
    });
  }
  
  // Suggest alerts if critical alerts exist
  if (context.recentIncidents.some((i) => i.status === "critical")) {
    suggestions.push({
      label: "View Critical Alerts",
      prompt: "Show me critical compliance alerts",
      icon: "AlertTriangle",
    });
  }
  
  return suggestions;
}
```

**Acceptance Criteria:**
- [ ] Suggests actions based on context
- [ ] Suggestions are relevant
- [ ] Suggestions appear in welcome screen
- [ ] Clicking suggestion sends prompt

**Estimated Time:** 4 hours

---

#### T3.10: Implement Action History & Undo
**File:** `src/lib/ai-assistant/action-history.ts` (NEW)

**Implementation:**
```typescript
interface ActionHistoryEntry {
  id: string;
  action: WorkflowAction;
  timestamp: Date;
  result: "success" | "error";
  canUndo: boolean;
}

export class ActionHistory {
  private history: ActionHistoryEntry[] = [];
  private maxHistory = 50;
  
  add(entry: ActionHistoryEntry) {
    this.history.unshift(entry);
    if (this.history.length > this.maxHistory) {
      this.history.pop();
    }
  }
  
  getRecent(count = 5): ActionHistoryEntry[] {
    return this.history.slice(0, count);
  }
  
  canUndo(actionId: string): boolean {
    const entry = this.history.find((e) => e.id === actionId);
    return entry?.canUndo || false;
  }
}
```

**Acceptance Criteria:**
- [ ] Tracks action history
- [ ] Shows recent actions
- [ ] Supports undo for reversible actions
- [ ] Persists across sessions (localStorage)

**Estimated Time:** 6 hours

---

#### T3.11: Add Action Confirmation Modals
**File:** `src/components/dashboard/ActionConfirmationModal.tsx` (NEW)

**Implementation:**
```tsx
interface ActionConfirmationModalProps {
  action: WorkflowAction;
  onConfirm: () => void;
  onCancel: () => void;
  open: boolean;
}

export function ActionConfirmationModal({
  action,
  onConfirm,
  onCancel,
  open,
}: ActionConfirmationModalProps) {
  if (!open) return null;
  
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      <div className="absolute inset-0 bg-black/60" onClick={onCancel} />
      <div
        className="relative rounded-xl p-6 max-w-md w-full mx-4"
        style={{
          background: "#000000",
          border: "1px solid rgba(255,255,255,0.08)",
        }}
      >
        <h3 className="text-lg font-semibold mb-2">Confirm Action</h3>
        <p className="text-sm opacity-70 mb-4">
          {action.confirmationMessage || `Are you sure you want to ${action.label.toLowerCase()}?`}
        </p>
        <div className="flex gap-3">
          <button onClick={onCancel} className="flex-1 px-4 py-2 rounded-lg">
            Cancel
          </button>
          <button onClick={onConfirm} className="flex-1 px-4 py-2 rounded-lg">
            Confirm
          </button>
        </div>
      </div>
    </div>
  );
}
```

**Acceptance Criteria:**
- [ ] Shows for actions requiring confirmation
- [ ] Matches design system
- [ ] Accessible (keyboard, focus management)
- [ ] Smooth animations

**Estimated Time:** 4 hours

---

#### T3.12: Enhance System Prompt for Action Detection
**File:** `src/app/api/ai-assistant/route.ts`

**Changes:**
Update `buildSystemPrompt` to include action generation instructions:

```
When your response suggests an action the user can take, include 
a structured action in your response using this format:

<action>
{
  "type": "generate_document",
  "label": "Generate Security Risk Assessment",
  "params": {
    "document_type": "security_risk_assessment",
    "location_id": "..."
  }
}
</action>

Available action types:
- generate_document: Generate compliance documents
- assign_training: Assign training to employees
- view_training_gaps: Navigate to training gaps page
- view_compliance_gaps: Navigate to compliance gaps
- view_audit_logs: Navigate to audit logs
- view_alert: Navigate to alert detail
- resolve_alert: Mark alert as resolved
- navigate: Navigate to any page
```

**Acceptance Criteria:**
- [ ] Prompt includes action format
- [ ] AI generates actions in correct format
- [ ] Actions are parsed correctly
- [ ] Fallback if AI doesn't generate actions

**Estimated Time:** 3 hours

---

### Phase 4: Polish & Testing (Week 4) - 4 Tickets

#### T3.13: UI Consistency Audit
**File:** All new components

**Tasks:**
- Review all components against design system
- Verify color palette usage
- Check spacing and typography
- Test responsive design
- Verify accessibility

**Acceptance Criteria:**
- [ ] All components match design system
- [ ] No design inconsistencies
- [ ] Responsive on all screen sizes
- [ ] WCAG AA compliant

**Estimated Time:** 4 hours

---

#### T3.14: Add Loading States for Async Actions
**File:** `src/components/dashboard/AIAssistant.tsx`

**Implementation:**
```typescript
const [loadingActions, setLoadingActions] = useState<Set<string>>(new Set());

const handleWorkflowAction = async (action: WorkflowAction) => {
  setLoadingActions((prev) => new Set(prev).add(action.id));
  
  try {
    await executeAction(action);
  } finally {
    setLoadingActions((prev) => {
      const next = new Set(prev);
      next.delete(action.id);
      return next;
    });
  }
};
```

**Acceptance Criteria:**
- [ ] Loading states show for all async actions
- [ ] Loading states are visually clear
- [ ] Actions disabled during loading
- [ ] Loading states match design system

**Estimated Time:** 3 hours

---

#### T3.15: Error Handling for Failed Actions
**File:** `src/components/dashboard/AIAssistant.tsx`

**Implementation:**
```typescript
const handleWorkflowAction = async (action: WorkflowAction) => {
  try {
    await executeAction(action);
    // Show success message
    addMessage({
      role: "assistant",
      content: `✅ ${action.label} completed successfully.`,
    });
  } catch (error) {
    // Show error message
    addMessage({
      role: "assistant",
      content: `❌ Failed to ${action.label.toLowerCase()}: ${error.message}\n\nWould you like to try again?`,
      actions: [
        {
          ...action,
          id: `${action.id}_retry`,
          label: `Retry: ${action.label}`,
        },
      ],
    });
  }
};
```

**Acceptance Criteria:**
- [ ] Errors are caught and displayed
- [ ] User-friendly error messages
- [ ] Retry options provided
- [ ] Errors logged for debugging

**Estimated Time:** 3 hours

---

#### T3.16: User Testing & Refinement
**File:** All files

**Tasks:**
- Conduct user testing sessions
- Gather feedback on UX
- Refine action detection
- Improve button labels
- Optimize workflow flows

**Acceptance Criteria:**
- [ ] User testing completed
- [ ] Feedback incorporated
- [ ] Action detection improved
- [ ] UX polished

**Estimated Time:** 8 hours

---

## 🔄 Integration Points

### Document Generation
- **API:** `/api/document-generation/generate`
- **Queue:** BullMQ document generation queue
- **Preview:** DocumentPreviewWrapper component

### Training Assignment
- **API:** `/api/training/assign` (may need to create)
- **Page:** `/dashboard/training`
- **Context:** Training data from Supabase

### Navigation
- **Router:** Next.js `useRouter()`
- **Routes:** All dashboard routes
- **Query Params:** Pre-fill filters

### Alerts
- **API:** `/api/alerts/[id]`
- **Page:** `/dashboard/audit-intelligence/alerts/[id]`
- **Context:** AlertsProvider

---

## 📊 Testing Strategy

### Unit Tests
- Action detection logic
- Action execution handlers
- Component rendering

### Integration Tests
- API response format
- Workflow execution
- Error handling

### E2E Tests
- Complete workflow flows
- User interactions
- Navigation

---

## 🚀 Deployment Plan

### Phase 1 Deployment
- Deploy foundation (types, API changes)
- Feature flag: `ENABLE_AI_WORKFLOWS=false`
- Test in staging

### Phase 2 Deployment
- Deploy core actions
- Enable for beta users
- Monitor usage

### Phase 3 Deployment
- Deploy advanced features
- Enable for all users
- Gather feedback

### Phase 4 Deployment
- Final polish
- Production release
- Documentation

---

## 📈 Success Metrics

### Week 1 Metrics
- Types defined and exported
- API returns actions (even if empty)
- Button component renders correctly

### Week 2 Metrics
- 3+ action types working
- Actions execute successfully
- User can complete workflows

### Week 3 Metrics
- Context suggestions appear
- Action history works
- Confirmation modals functional

### Week 4 Metrics
- >85% action detection accuracy
- >95% action execution success
- User satisfaction >4/5

---

## 🎯 MVP Scope (Quick Win)

For immediate value, implement:

1. **Generate Document** action (highest value)
2. **Navigate** action (easiest)
3. **View Training Gaps** action (useful)

**Estimated Time:** 1 week  
**Value:** High (users can generate documents from chat)

---

## 📝 Notes

- All actions must respect user permissions
- Actions should be idempotent where possible
- Consider rate limiting for expensive actions
- Log all action executions for analytics
- Support undo for reversible actions

---

**Status:** Ready for Implementation  
**Next Step:** Create Phase 3 Epic and tickets



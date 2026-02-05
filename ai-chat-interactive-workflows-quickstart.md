# Interactive AI Chat Workflows - Quick Start Guide
## Get Started in 30 Minutes

This guide helps you implement the MVP (Minimum Viable Product) version of interactive workflows in the AI chat agent.

---

## 🎯 MVP Scope

**Goal:** Enable users to generate documents directly from chat with one click.

**Features:**
1. ✅ AI detects document generation requests
2. ✅ Response includes "Generate Document" button
3. ✅ Button triggers document generation
4. ✅ Shows loading state
5. ✅ Opens preview when ready

**Time Estimate:** 1 week (5-6 hours of focused work)

---

## 🚀 Step-by-Step Implementation

### Step 1: Add Types (30 minutes)

**File:** `src/lib/ai-assistant/types.ts` (create or extend)

```typescript
export type ActionType = "generate_document" | "navigate";

export interface WorkflowAction {
  id: string;
  type: ActionType;
  label: string;
  icon?: string;
  params: Record<string, unknown>;
  variant?: "primary" | "secondary";
}

export interface AIResponseWithActions {
  text: string;
  actions?: WorkflowAction[];
}
```

**Test:**
```bash
npm run typecheck
```

---

### Step 2: Update API Response (1 hour)

**File:** `src/app/api/ai-assistant/route.ts`

**Changes:**
1. Import action detector
2. Detect actions from response
3. Include in response

```typescript
import { detectActionsFromResponse } from "@/lib/ai-assistant/action-detector";

// After getting AI response
const textResponse = extractTextFromResponse(response);
const actions = detectActionsFromResponse(textResponse, context, section);

return NextResponse.json({
  response: textResponse,
  actions: actions,  // NEW
  context: {
    employeeCount: context.employeeCount,
    complianceScore: context.complianceScore,
  },
});
```

**Test:**
- Call API and verify `actions` array in response
- Verify backward compatibility (actions optional)

---

### Step 3: Create Action Detector (2 hours)

**File:** `src/lib/ai-assistant/action-detector.ts` (NEW)

```typescript
import type { OrgContext } from "@/app/api/ai-assistant/route";
import type { WorkflowAction } from "./types";

export function detectActionsFromResponse(
  response: string,
  context: OrgContext,
  section?: string
): WorkflowAction[] {
  const actions: WorkflowAction[] = [];
  const responseLower = response.toLowerCase();
  
  // Document generation detection
  if (
    (responseLower.includes("generate") || 
     responseLower.includes("create")) &&
    (responseLower.includes("report") ||
     responseLower.includes("assessment") ||
     responseLower.includes("document"))
  ) {
    // Determine document type
    let documentType = "security_risk_assessment"; // default
    
    if (responseLower.includes("audit") || responseLower.includes("log")) {
      documentType = "audit_log_summary";
    } else if (responseLower.includes("training")) {
      documentType = "training_documentation";
    } else if (responseLower.includes("exposure") || responseLower.includes("bbp")) {
      documentType = "exposure_control_plan";
    } else if (responseLower.includes("baa") || responseLower.includes("business associate")) {
      documentType = "baa_registry";
    }
    
    actions.push({
      id: `action_${Date.now()}`,
      type: "generate_document",
      label: `Generate ${formatDocumentName(documentType)}`,
      icon: "FileText",
      params: {
        document_type: documentType,
        location_id: context.locationId || undefined,
      },
      variant: "primary",
    });
  }
  
  return actions;
}

function formatDocumentName(type: string): string {
  const names: Record<string, string> = {
    security_risk_assessment: "Security Risk Assessment",
    audit_log_summary: "Audit Log Summary",
    training_documentation: "Training Documentation",
    exposure_control_plan: "Exposure Control Plan",
    baa_registry: "BAA Registry",
  };
  return names[type] || type;
}
```

**Test:**
```typescript
// Test cases
detectActionsFromResponse("Generate my audit report", context)
// Should return: [{ type: "generate_document", document_type: "audit_log_summary" }]

detectActionsFromResponse("What's the weather?", context)
// Should return: []
```

---

### Step 4: Create WorkflowButton Component (1.5 hours)

**File:** `src/components/dashboard/WorkflowButton.tsx` (NEW)

```tsx
"use client";

import { WorkflowAction } from "@/lib/ai-assistant/types";
import { FileText, ExternalLink, Loader2 } from "lucide-react";

const iconMap: Record<string, typeof FileText> = {
  FileText,
  ExternalLink,
};

interface WorkflowButtonProps {
  action: WorkflowAction;
  onClick: () => void | Promise<void>;
  loading?: boolean;
}

export function WorkflowButton({ action, onClick, loading }: WorkflowButtonProps) {
  const Icon = action.icon ? iconMap[action.icon] : FileText;
  const variant = action.variant || "primary";
  
  const styles = {
    primary: {
      bg: "rgba(88, 166, 255, 0.1)",
      border: "rgba(88, 166, 255, 0.3)",
      color: "#58A6FF",
    },
    secondary: {
      bg: "rgba(255,255,255,0.02)",
      border: "rgba(255,255,255,0.08)",
      color: "rgba(255,255,255,0.82)",
    },
  }[variant];
  
  return (
    <button
      onClick={onClick}
      disabled={loading}
      className="w-full px-4 py-3 rounded-lg text-sm font-medium transition-all duration-200 flex items-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed hover:scale-[1.02] active:scale-[0.98]"
      style={{
        background: styles.bg,
        border: `1px solid ${styles.border}`,
        color: styles.color,
      }}
    >
      {loading ? (
        <Loader2 className="w-4 h-4 animate-spin" />
      ) : (
        <Icon className="w-4 h-4" />
      )}
      <span className="flex-1 text-left">{action.label}</span>
    </button>
  );
}
```

**Test:**
- Render component in Storybook or test page
- Verify styles match design system
- Test loading state
- Test disabled state

---

### Step 5: Integrate into MessageBubble (1 hour)

**File:** `src/components/dashboard/AIAssistant.tsx`

**Changes:**
1. Update Message type
2. Render actions
3. Handle action clicks

```typescript
// Update Message type
type Message = {
  id: string;
  role: "user" | "assistant";
  content: string;
  actions?: WorkflowAction[];  // NEW
  timestamp: Date;
};

// In sendMessage function, update response handling
const assistantMessage: Message = {
  id: (Date.now() + 1).toString(),
  role: "assistant",
  content: data.response,
  actions: data.actions || [],  // NEW
  timestamp: new Date(),
};

// In MessageBubble component
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

**Test:**
- Send message that triggers action
- Verify button appears
- Click button and verify handler called

---

### Step 6: Implement Action Handler (1 hour)

**File:** `src/components/dashboard/AIAssistant.tsx`

```typescript
const [loadingActions, setLoadingActions] = useState<Set<string>>(new Set());

const handleWorkflowAction = async (action: WorkflowAction) => {
  setLoadingActions((prev) => new Set(prev).add(action.id));
  
  try {
    switch (action.type) {
      case "generate_document":
        await handleDocumentGeneration(action.params);
        break;
      case "navigate":
        router.push(action.params.path as string);
        break;
      default:
        console.warn("Unknown action type:", action.type);
    }
  } catch (error) {
    addMessage({
      role: "assistant",
      content: `❌ Failed to ${action.label.toLowerCase()}: ${error.message}`,
    });
  } finally {
    setLoadingActions((prev) => {
      const next = new Set(prev);
      next.delete(action.id);
      return next;
    });
  }
};

const handleDocumentGeneration = async (params: {
  document_type: string;
  location_id?: string;
}) => {
  if (!orgId || !activeLocationId) {
    throw new Error("Organization and location required");
  }
  
  // Call document generation API (use existing MCP tool execution)
  const response = await fetch("/api/ai-assistant", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      message: `Generate ${params.document_type} for location ${params.location_id || activeLocationId}`,
      orgId,
      locationId: params.location_id || activeLocationId,
      accessToken: (await supabase.auth.getSession()).data.session?.access_token,
      section: "audit-intelligence",
    }),
  });
  
  const data = await response.json();
  
  // Extract job ID from response (existing logic)
  const docJobInfo = extractDocJobInfo(data.response);
  if (docJobInfo) {
    documentPreview.startPollingJob({
      jobId: docJobInfo.jobId,
      documentType: docJobInfo.documentType as DocumentType,
      orgId,
      locationId: params.location_id || activeLocationId,
    });
  }
  
  addMessage({
    role: "assistant",
    content: `✅ Document generation started. I'll notify you when it's ready.`,
  });
};
```

**Test:**
- Click "Generate Document" button
- Verify API call made
- Verify loading state shows
- Verify document preview starts
- Verify success message appears

---

## ✅ MVP Checklist

- [ ] Types defined and exported
- [ ] API returns actions array
- [ ] Action detector identifies document generation requests
- [ ] WorkflowButton component renders correctly
- [ ] Actions appear in message bubbles
- [ ] Clicking button triggers document generation
- [ ] Loading state works
- [ ] Document preview opens when ready
- [ ] Error handling works
- [ ] Design system compliance verified

---

## 🧪 Testing

### Manual Testing
1. Open AI assistant
2. Type: "Generate my audit report"
3. Verify button appears
4. Click button
5. Verify loading state
6. Verify document generates
7. Verify preview opens

### Edge Cases
- No actions detected (should work normally)
- Action execution fails (should show error)
- Multiple actions (should render all)
- Rapid clicks (should prevent duplicate)

---

## 🚀 Next Steps After MVP

Once MVP works:

1. **Add More Action Types**
   - Training assignment
   - Navigation
   - Alert viewing

2. **Improve Detection**
   - Use AI to generate actions (not just pattern matching)
   - Context-aware suggestions

3. **Enhance UX**
   - Action descriptions
   - Confirmation modals
   - Action history

4. **Polish**
   - Better error messages
   - Loading animations
   - Success states

---

## 📝 Notes

- Start with pattern matching (fast, simple)
- Upgrade to AI-generated actions later (flexible, smart)
- Keep actions optional (backward compatible)
- Test thoroughly before production

---

**Estimated Total Time:** 5-6 hours  
**Difficulty:** Medium  
**Dependencies:** None (uses existing infrastructure)



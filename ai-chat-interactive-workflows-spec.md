# Interactive AI Chat Agent with Workflow Buttons
## Design Specification & Implementation Plan

**Epic:** Enhanced AI Assistant with Interactive Workflows  
**Inspired by:** Manus AI's actionable chat interface  
**Timeline:** 3-4 weeks  
**Priority:** High (Differentiates from competitors)

---

## 🎯 Vision

Transform the AI assistant from a conversational Q&A tool into an **actionable workflow engine** where users can:
- Ask questions and get answers
- **Press buttons to trigger workflows** (generate documents, assign training, etc.)
- See **context-aware action suggestions** based on conversation
- Complete compliance tasks **without leaving the chat**

---

## 📋 Current State Analysis

### What Works Today ✅
- AI assistant responds to questions
- MCP tools for document generation (audit-intelligence section)
- Base tools for compliance queries
- Document preview integration (partial)
- Clean black/white luxury UI

### What's Missing ❌
- **No interactive buttons** in chat responses
- **No workflow triggers** from chat
- **No action suggestions** based on context
- **No structured response format** for actions
- Limited integration with existing workflows

---

## 🎨 Design Specification

### 1. Structured Response Format

AI responses will include both text and actionable buttons:

```typescript
type AIResponse = {
  text: string;  // Natural language response
  actions?: WorkflowAction[];  // Optional actionable buttons
  suggestions?: QuickAction[];  // Context-aware suggestions
};

type WorkflowAction = {
  id: string;
  type: ActionType;
  label: string;
  icon?: string;
  description?: string;
  params: Record<string, unknown>;
  variant?: "primary" | "secondary" | "danger";
};

type QuickAction = {
  label: string;
  prompt: string;  // Pre-filled prompt to send
};
```

### 2. Available Workflow Actions

#### Document Generation Actions
```typescript
{
  type: "generate_document",
  label: "Generate Security Risk Assessment",
  params: {
    document_type: "security_risk_assessment",
    location_id: "...",
    date_range?: { start: "...", end: "..." }
  }
}
```

#### Training Actions
```typescript
{
  type: "assign_training",
  label: "Assign HIPAA Training to John Doe",
  params: {
    user_id: "...",
    course_name: "HIPAA Certification",
    due_date: "..."
  }
}

{
  type: "view_training_gaps",
  label: "View Training Gaps",
  params: {
    location_id: "..."
  }
}
```

#### Compliance Actions
```typescript
{
  type: "view_compliance_gaps",
  label: "View Compliance Gaps",
  params: {
    location_id: "...",
    framework?: "hipaa" | "osha" | "all"
  }
}

{
  type: "view_audit_logs",
  label: "View Audit Logs",
  params: {
    location_id: "...",
    date_range: { start: "...", end: "..." },
    actor_name?: "..."
  }
}
```

#### Alert Actions
```typescript
{
  type: "view_alert",
  label: "View Alert Details",
  params: {
    alert_id: "..."
  }
}

{
  type: "resolve_alert",
  label: "Mark Alert as Resolved",
  params: {
    alert_id: "..."
  }
}
```

#### Navigation Actions
```typescript
{
  type: "navigate",
  label: "Go to Employee Matching",
  params: {
    path: "/dashboard/audit-intelligence/employee-matching"
  }
}
```

### 3. UI Component Design

#### Action Button Component
```tsx
<WorkflowButton
  action={action}
  onClick={() => handleWorkflowAction(action)}
  variant={action.variant || "primary"}
/>
```

**Visual Design:**
- Matches existing black/white luxury aesthetic
- Primary actions: Blue accent (#58A6FF)
- Secondary actions: White with border
- Danger actions: Red accent (#F85149)
- Hover states: Scale and opacity transitions
- Icons: Lucide React icons

#### Action Group Component
```tsx
<ActionGroup
  title="Available Actions"
  actions={actions}
  layout="grid" | "list"
/>
```

**Layout Options:**
- **Grid**: 2-3 columns for multiple actions
- **List**: Vertical stack for single-column layout
- **Inline**: Horizontal row for 2-3 actions

### 4. Context-Aware Suggestions

AI will suggest actions based on:
- **Current conversation context**
- **Data availability** (e.g., "Generate report" if data exists)
- **User role** (admin sees more actions than employee)
- **Recent alerts** (suggest viewing/resolving)
- **Missing data** (suggest setup actions)

**Example Suggestions:**
```
User: "What's my compliance score?"
AI: "Your compliance score is 72%. Here are some actions you can take:"
  → [Generate Security Risk Assessment]
  → [View Compliance Gaps]
  → [Assign Training]
```

---

## 🏗️ Architecture

### 1. Enhanced API Response Format

**File:** `src/app/api/ai-assistant/route.ts`

Modify response to include structured actions:

```typescript
return NextResponse.json({
  response: textResponse,
  actions: detectedActions,  // NEW
  suggestions: contextSuggestions,  // NEW
  context: {
    employeeCount: context.employeeCount,
    complianceScore: context.complianceScore,
  },
});
```

### 2. Action Detection System

**File:** `src/lib/ai-assistant/action-detector.ts` (NEW)

Detect actionable intents from AI responses:

```typescript
export function detectActions(
  response: string,
  context: OrgContext,
  section?: string
): WorkflowAction[] {
  const actions: WorkflowAction[] = [];
  
  // Pattern matching for document generation
  if (response.includes("generate") || response.includes("create")) {
    // Detect document type from context
    // Return appropriate action
  }
  
  // Pattern matching for training assignment
  if (response.includes("assign training") || response.includes("training gap")) {
    // Return training action
  }
  
  return actions;
}
```

### 3. Workflow Execution Handler

**File:** `src/components/dashboard/AIAssistant.tsx`

Handle workflow action execution:

```typescript
const handleWorkflowAction = async (action: WorkflowAction) => {
  switch (action.type) {
    case "generate_document":
      await triggerDocumentGeneration(action.params);
      break;
    case "assign_training":
      await assignTraining(action.params);
      break;
    case "navigate":
      router.push(action.params.path);
      break;
    // ... other actions
  }
};
```

### 4. Enhanced System Prompt

**File:** `src/app/api/ai-assistant/route.ts`

Update system prompt to encourage action suggestions:

```
When appropriate, suggest actionable next steps. For example:
- If user asks about compliance score → suggest "Generate Security Risk Assessment"
- If user asks about training gaps → suggest "Assign Training" buttons
- If user asks about alerts → suggest "View Alert" or "Resolve Alert" buttons

Format action suggestions as structured JSON in your response.
```

---

## 📐 UI/UX Specifications

### Button Styles

**Primary Action Button:**
```css
background: rgba(88, 166, 255, 0.1)
border: 1px solid rgba(88, 166, 255, 0.3)
color: #58A6FF
hover: scale-[1.02], opacity-90
```

**Secondary Action Button:**
```css
background: rgba(255,255,255,0.02)
border: 1px solid rgba(255,255,255,0.08)
color: rgba(255,255,255,0.82)
hover: bg-white/[0.05]
```

**Danger Action Button:**
```css
background: rgba(248, 81, 73, 0.1)
border: 1px solid rgba(248, 81, 73, 0.3)
color: #F85149
```

### Layout Examples

**Single Action:**
```
[AI Response Text]

┌─────────────────────────────────────┐
│  📄 Generate Security Risk Assessment│
└─────────────────────────────────────┘
```

**Multiple Actions (Grid):**
```
[AI Response Text]

┌──────────────────────┐  ┌──────────────────────┐
│ 📄 Generate Report    │  │ 📊 View Audit Logs  │
└──────────────────────┘  └──────────────────────┘
┌──────────────────────┐  ┌──────────────────────┐
│ 🎓 Assign Training   │  │ ⚠️  View Alerts      │
└──────────────────────┘  └──────────────────────┘
```

**Action with Description:**
```
[AI Response Text]

┌─────────────────────────────────────────────┐
│ 📄 Generate Security Risk Assessment        │
│ Generate a comprehensive HIPAA Security     │
│ Risk Assessment for your practice           │
└─────────────────────────────────────────────┘
```

---

## 🔄 Workflow Integration

### Document Generation Flow

1. User asks: "Generate my Q4 audit report"
2. AI responds with text + action button
3. User clicks "Generate Audit Report"
4. System triggers document generation job
5. Show loading state in chat
6. When complete, show preview button
7. User can preview/edit/download

### Training Assignment Flow

1. User asks: "Who needs HIPAA training?"
2. AI responds with list + action buttons
3. User clicks "Assign Training to John Doe"
4. System opens training assignment modal (or navigates)
5. Pre-fills course and user
6. User confirms assignment

### Alert Resolution Flow

1. User asks: "What alerts do I have?"
2. AI responds with alert summary + action buttons
3. User clicks "View Alert" or "Resolve Alert"
4. System navigates to alert detail page
5. Or resolves alert directly (with confirmation)

---

## 📦 Implementation Plan

### Phase 1: Foundation (Week 1)
**Tickets:**
- T3.1: Define WorkflowAction types and interfaces
- T3.2: Enhance API response format to include actions
- T3.3: Create action detection system
- T3.4: Build WorkflowButton component

### Phase 2: Core Actions (Week 2)
**Tickets:**
- T3.5: Implement document generation action handler
- T3.6: Implement training assignment action handler
- T3.7: Implement navigation action handler
- T3.8: Integrate actions into MessageBubble component

### Phase 3: Advanced Features (Week 3)
**Tickets:**
- T3.9: Add context-aware action suggestions
- T3.10: Implement action history/undo
- T3.11: Add action confirmation modals (for destructive actions)
- T3.12: Enhance system prompt for action detection

### Phase 4: Polish & Testing (Week 4)
**Tickets:**
- T3.13: UI consistency audit (match design system)
- T3.14: Add loading states for async actions
- T3.15: Error handling for failed actions
- T3.16: User testing and refinement

---

## 🎯 Success Metrics

### User Engagement
- **Action Click Rate:** >30% of responses with actions get clicked
- **Task Completion:** Users complete workflows 2x faster
- **Return Rate:** Users return to chat 3x more often

### Technical Metrics
- **Action Detection Accuracy:** >85% of relevant responses include actions
- **Action Execution Success:** >95% of actions execute successfully
- **Response Time:** <500ms for action execution

---

## 🔍 Example Conversations

### Example 1: Document Generation
```
User: "I need a Security Risk Assessment for my practice"

AI: "I can generate a comprehensive HIPAA Security Risk Assessment 
     for your practice. This will include analysis of your current 
     security controls, identified risks, and recommended 
     remediation steps.

     [Generate Security Risk Assessment] [View Sample]
```

### Example 2: Training Assignment
```
User: "Who needs to complete HIPAA training?"

AI: "I found 3 employees who need to complete HIPAA training:
     1. John Doe (hired 45 days ago)
     2. Jane Smith (training expired 10 days ago)
     3. Bob Johnson (never assigned)

     [Assign Training to All] [View Training Gaps]
```

### Example 3: Compliance Gaps
```
User: "What compliance gaps do we have?"

AI: "I found 2 critical compliance gaps:
     1. Missing Security Risk Assessment
     2. 3 employees without HIPAA training

     [Generate Security Risk Assessment]
     [Assign HIPAA Training]
     [View All Compliance Gaps]
```

---

## 🚀 Quick Wins (MVP)

For immediate value, implement these 3 actions first:

1. **Generate Document** (highest value)
   - Trigger document generation
   - Show loading state
   - Open preview when ready

2. **View [Resource]** (navigation)
   - Navigate to relevant pages
   - Pre-fill filters when possible

3. **Assign Training** (workflow trigger)
   - Open training assignment
   - Pre-fill course and user

---

## 📝 Technical Notes

### Action Detection Strategy

**Option A: Pattern Matching (Fast, Simple)**
- Regex patterns in response text
- Pros: Fast, no AI overhead
- Cons: Less flexible, may miss edge cases

**Option B: AI-Generated Actions (Flexible, Smart)**
- Claude generates actions in structured format
- Pros: Context-aware, handles edge cases
- Cons: Slightly slower, requires prompt engineering

**Recommendation:** Hybrid approach
- Use pattern matching for common cases (fast)
- Use AI generation for complex cases (smart)
- Cache common patterns for performance

### Action Execution

All actions should:
- Show loading state immediately
- Handle errors gracefully
- Provide user feedback
- Support undo where possible

### Security Considerations

- Verify user permissions before executing actions
- Validate action parameters server-side
- Rate limit action execution
- Audit all action executions

---

## 🎨 Design System Compliance

All components must match existing design system:

✅ Pure black background (#000000)  
✅ White text with opacity levels  
✅ Subtle borders (rgba(255,255,255,0.06))  
✅ Strategic accent colors (blue, red, green)  
✅ JetBrains Mono for labels  
✅ Smooth transitions (0.2s-0.3s)  
✅ Proper focus states  
✅ Glassmorphism effects  

---

## 📊 Comparison: Before vs After

### Before (Current)
```
User: "Generate my audit report"
AI: "I can help you generate an audit report. 
     The document generation has been started. 
     Job ID: abc123"
[User must manually check document status]
```

### After (With Workflows)
```
User: "Generate my audit report"
AI: "I'll generate your Q4 audit report now. 
     This will include all audit events from 
     the last 90 days.

     [Generate Audit Report] [View Sample Report]"
[User clicks button → Document generates → Preview opens]
```

---

## ✅ Acceptance Criteria

### Must Have
- [ ] AI responses can include actionable buttons
- [ ] Buttons trigger workflows (documents, training, navigation)
- [ ] Actions match design system perfectly
- [ ] Loading states for async actions
- [ ] Error handling for failed actions
- [ ] Works in both default and audit-intelligence sections

### Should Have
- [ ] Context-aware action suggestions
- [ ] Action history/undo capability
- [ ] Confirmation modals for destructive actions
- [ ] Action analytics (track which actions are used)

### Nice to Have
- [ ] Custom action workflows (user-defined)
- [ ] Action templates (save common workflows)
- [ ] Multi-step workflows (wizard-style)
- [ ] Action scheduling (run later)

---

## 🔗 Related Files

**Core Implementation:**
- `src/components/dashboard/AIAssistant.tsx` - Main chat component
- `src/app/api/ai-assistant/route.ts` - API endpoint
- `src/lib/ai-assistant/mcp-tools.ts` - MCP tool definitions

**New Files to Create:**
- `src/lib/ai-assistant/action-detector.ts` - Action detection logic
- `src/lib/ai-assistant/workflow-handler.ts` - Workflow execution
- `src/components/dashboard/WorkflowButton.tsx` - Button component
- `src/components/dashboard/ActionGroup.tsx` - Action group component

**Integration Points:**
- Document generation: `src/lib/queue.ts` (BullMQ)
- Training assignment: `/api/training/assign`
- Navigation: Next.js router
- Alerts: `/api/alerts/[id]`

---

## 🎬 Next Steps

1. **Review this spec** with team
2. **Create Phase 3 Epic** in project management
3. **Break down into tickets** (16 tickets as outlined)
4. **Start with Phase 1** (Foundation)
5. **Iterate based on user feedback**

---

**Status:** Ready for Implementation  
**Last Updated:** 2025-01-XX  
**Owner:** AI Assistant Team



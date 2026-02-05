# Interactive AI Chat Workflows - Visual Wireframes
## UI/UX Mockups & Component Specifications

---

## 🎨 Design Principles

1. **Minimal & Clean:** Buttons appear only when relevant
2. **Context-Aware:** Actions match conversation context
3. **Progressive Disclosure:** Show primary actions first, secondary on hover
4. **Visual Hierarchy:** Primary actions more prominent than secondary
5. **Consistent Spacing:** 16px gaps, 12px padding

---

## 📐 Component Wireframes

### 1. Single Action Button

```
┌─────────────────────────────────────────────────────┐
│ [AI Response Text]                                   │
│                                                      │
│ I can generate a Security Risk Assessment for your  │
│ practice. This will analyze your current security   │
│ controls and identify risks.                        │
│                                                      │
│ ┌─────────────────────────────────────────────────┐ │
│ │ 📄 Generate Security Risk Assessment            │ │
│ └─────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────┘
```

**Specifications:**
- Width: Full width of message bubble
- Height: 48px (py-3 = 12px top/bottom)
- Border radius: 8px (rounded-lg)
- Icon: 16px (w-4 h-4)
- Text: 14px (text-sm)
- Gap between icon and text: 8px (gap-2)

---

### 2. Multiple Actions (Grid Layout)

```
┌─────────────────────────────────────────────────────┐
│ [AI Response Text]                                   │
│                                                      │
│ I found 3 employees who need HIPAA training:         │
│ • John Doe (hired 45 days ago)                      │
│ • Jane Smith (training expired)                     │
│ • Bob Johnson (never assigned)                      │
│                                                      │
│ ┌──────────────────────┐  ┌──────────────────────┐ │
│ │ 🎓 Assign Training   │  │ 📊 View Training Gaps │ │
│ └──────────────────────┘  └──────────────────────┘ │
│                                                      │
│ ┌──────────────────────┐                            │
│ │ ⚠️  View All Alerts   │                            │
│ └──────────────────────┘                            │
└─────────────────────────────────────────────────────┘
```

**Specifications:**
- Grid: 2 columns on desktop, 1 column on mobile
- Gap: 12px between buttons
- Responsive breakpoint: <640px (sm)

---

### 3. Action with Description

```
┌─────────────────────────────────────────────────────┐
│ [AI Response Text]                                   │
│                                                      │
│ ┌─────────────────────────────────────────────────┐ │
│ │ 📄 Generate Security Risk Assessment            │ │
│ │ Generate a comprehensive HIPAA Security Risk   │ │
│ │ Assessment for your practice                    │ │
│ └─────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────┘
```

**Specifications:**
- Description: 12px text (text-xs)
- Opacity: 60% (opacity-60)
- Spacing: 4px margin-top (mt-1)

---

### 4. Loading State

```
┌─────────────────────────────────────────────────────┐
│ [AI Response Text]                                   │
│                                                      │
│ ┌─────────────────────────────────────────────────┐ │
│ │ ⏳ Generate Security Risk Assessment            │ │
│ └─────────────────────────────────────────────────┘ │
│                                                      │
│ Generating document... This may take a few moments. │
└─────────────────────────────────────────────────────┘
```

**Specifications:**
- Spinner: 16px animated (Loader2)
- Button disabled during loading
- Opacity: 50% when disabled
- Additional status text below button

---

### 5. Action Group with Title

```
┌─────────────────────────────────────────────────────┐
│ [AI Response Text]                                   │
│                                                      │
│ Available Actions:                                   │
│ ┌─────────────────────────────────────────────────┐ │
│ │ 📄 Generate Security Risk Assessment            │ │
│ └─────────────────────────────────────────────────┘ │
│ ┌─────────────────────────────────────────────────┐ │
│ │ 📊 View Compliance Gaps                        │ │
│ └─────────────────────────────────────────────────┘ │
│ ┌─────────────────────────────────────────────────┐ │
│ │ 🎓 Assign Training                              │ │
│ └─────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────┘
```

**Specifications:**
- Title: 12px, uppercase, JetBrains Mono
- Title opacity: 50%
- Title margin-bottom: 8px
- Actions: Vertical stack, 8px gap

---

### 6. Quick Action Suggestions (Welcome Screen)

```
┌─────────────────────────────────────────────────────┐
│                                                      │
│          Hi! I'm your Compliance Assistant          │
│                                                      │
│ ┌─────────────────────────────────────────────────┐ │
│ │ 💡 Quick Actions                                │ │
│ │                                                 │ │
│ │ ┌───────────────────────────────────────────┐ │ │
│ │ │ 📄 Generate Security Risk Assessment      │ │ │
│ │ └───────────────────────────────────────────┘ │ │
│ │ ┌───────────────────────────────────────────┐ │ │
│ │ │ 🎓 View Training Gaps                     │ │ │
│ │ └───────────────────────────────────────────┘ │ │
│ │ ┌───────────────────────────────────────────┐ │ │
│ │ │ ⚠️  View Compliance Alerts                 │ │ │
│ │ └───────────────────────────────────────────┘ │ │
│ └─────────────────────────────────────────────────┘ │
│                                                      │
│ TRY_ASKING                                           │
│ [Quick prompts...]                                   │
└─────────────────────────────────────────────────────┘
```

**Specifications:**
- Section title: 10px, uppercase, JetBrains Mono
- Actions: Same style as message actions
- Max 3-4 suggestions
- Context-aware (only show relevant suggestions)

---

### 7. Error State with Retry

```
┌─────────────────────────────────────────────────────┐
│ [AI Response Text]                                   │
│                                                      │
│ ❌ Failed to generate document: Connection timeout  │
│                                                      │
│ ┌─────────────────────────────────────────────────┐ │
│ │ 🔄 Retry: Generate Security Risk Assessment    │ │
│ └─────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────┘
```

**Specifications:**
- Error message: Red text (#F85149)
- Retry button: Secondary variant
- Icon: RefreshCw or RotateCw

---

### 8. Success State

```
┌─────────────────────────────────────────────────────┐
│ [AI Response Text]                                   │
│                                                      │
│ ✅ Document generation started. I'll notify you     │
│ when it's ready.                                     │
│                                                      │
│ ┌─────────────────────────────────────────────────┐ │
│ │ 📄 View Document Preview                       │ │
│ └─────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────┘
```

**Specifications:**
- Success message: Green text (#22C55E)
- Follow-up action: Primary variant
- Icon: CheckCircle2 or FileText

---

## 🎨 Color Palette

### Primary Actions
- Background: `rgba(88, 166, 255, 0.1)`
- Border: `rgba(88, 166, 255, 0.3)`
- Text: `#58A6FF`
- Hover: `rgba(88, 166, 255, 0.15)`

### Secondary Actions
- Background: `rgba(255,255,255,0.02)`
- Border: `rgba(255,255,255,0.08)`
- Text: `rgba(255,255,255,0.82)`
- Hover: `rgba(255,255,255,0.05)`

### Danger Actions
- Background: `rgba(248, 81, 73, 0.1)`
- Border: `rgba(248, 81, 73, 0.3)`
- Text: `#F85149`
- Hover: `rgba(248, 81, 73, 0.15)`

### Success Actions
- Background: `rgba(34, 197, 94, 0.1)`
- Border: `rgba(34, 197, 94, 0.3)`
- Text: `#22C55E`
- Hover: `rgba(34, 197, 94, 0.15)`

---

## 📱 Responsive Design

### Desktop (>640px)
- Actions: Grid layout (2 columns)
- Button width: Full width of container
- Spacing: 12px gaps

### Mobile (<640px)
- Actions: Single column
- Button width: Full width
- Spacing: 8px gaps
- Touch targets: Minimum 44px height

---

## ♿ Accessibility

### Keyboard Navigation
- Tab order: Actions follow message order
- Enter/Space: Activates action
- Escape: Closes modals
- Focus ring: `ring-2 ring-[#58A6FF]`

### Screen Readers
- ARIA labels on all buttons
- Action descriptions read aloud
- Loading states announced
- Error messages announced

### Visual
- Color contrast: WCAG AA compliant
- Focus indicators: Visible
- Loading indicators: Animated
- Error states: Clear and distinct

---

## 🎬 Animation Specs

### Button Hover
- Duration: 200ms
- Easing: ease-in-out
- Properties: background, scale
- Scale: `scale-[1.02]`

### Button Active
- Duration: 100ms
- Scale: `scale-[0.98]`

### Loading Spinner
- Duration: 1s (infinite)
- Easing: linear
- Rotation: 360deg

### Modal Entrance
- Duration: 300ms
- Easing: ease-out
- Properties: opacity, transform
- Transform: `translate-y-[-10px]`

---

## 📐 Spacing System

```
Action Group
├── Title margin-bottom: 8px
├── Action gap: 8px (vertical)
└── Action padding: 12px (py-3)

Button Internal
├── Padding: 12px 16px (px-4 py-3)
├── Icon-text gap: 8px (gap-2)
└── Icon size: 16px (w-4 h-4)

Message Bubble
├── Action margin-top: 16px (mt-4)
└── Action group gap: 8px (space-y-2)
```

---

## 🔍 Component States

### Default
- Normal appearance
- Hover effect available
- Clickable

### Loading
- Spinner icon replaces action icon
- Button disabled
- Opacity: 50%
- Cursor: not-allowed

### Disabled
- Opacity: 50%
- No hover effect
- Cursor: not-allowed
- Tooltip: "Action unavailable"

### Success
- Green accent color
- Checkmark icon
- Optional: "Completed" badge

### Error
- Red accent color
- Alert icon
- Retry button available

---

## 🎯 Interaction Patterns

### Single Click
- Immediate action execution
- Show loading state
- Update UI on completion

### Confirmation Required
- Show modal
- User confirms
- Execute action
- Show result

### Multi-Step
- Step 1: User clicks action
- Step 2: Show form/modal
- Step 3: User completes form
- Step 4: Execute action
- Step 5: Show result

---

## 📊 Layout Examples

### Example 1: Document Generation Flow
```
User: "Generate my audit report"

AI: "I'll generate your Q4 audit report now. 
     This includes all audit events from the 
     last 90 days.

     ┌─────────────────────────────────────┐
     │ 📄 Generate Q4 Audit Report        │
     └─────────────────────────────────────┘

     [Loading...]

     ✅ Report generated successfully!

     ┌─────────────────────────────────────┐
     │ 📄 View Report Preview              │
     │ 📥 Download PDF                     │
     └─────────────────────────────────────┘
```

### Example 2: Training Assignment Flow
```
User: "Who needs HIPAA training?"

AI: "I found 3 employees who need HIPAA training:
     • John Doe (hired 45 days ago)
     • Jane Smith (training expired)
     • Bob Johnson (never assigned)

     ┌──────────────────────┐  ┌──────────────────────┐
     │ 🎓 Assign to All    │  │ 📊 View Training Gaps│
     └──────────────────────┘  └──────────────────────┘

     [User clicks "Assign to All"]

     ┌─────────────────────────────────────┐
     │ Select Training Course:             │
     │ [HIPAA Certification ▼]            │
     │                                     │
     │ Due Date: [30 days from now]       │
     │                                     │
     │ ┌──────────┐  ┌──────────┐          │
     │ │ Cancel   │  │ Assign   │          │
     │ └──────────┘  └──────────┘          │
     └─────────────────────────────────────┘
```

---

## 🎨 Icon Mapping

| Action Type | Icon | Lucide Name |
|------------|------|-------------|
| generate_document | 📄 | FileText |
| assign_training | 🎓 | UserCheck |
| view_training_gaps | 📊 | BarChart3 |
| view_compliance_gaps | ⚠️ | AlertTriangle |
| view_audit_logs | 📋 | FileSearch |
| view_alert | 🔔 | Bell |
| resolve_alert | ✅ | CheckCircle2 |
| navigate | 🔗 | ExternalLink |
| export_data | 📥 | Download |

---

## 📝 Implementation Notes

1. **Button Width:** Full width of message bubble (max-w-[80%])
2. **Icon Alignment:** Left-aligned with text
3. **Text Alignment:** Left-aligned
4. **Responsive:** Stack vertically on mobile
5. **Accessibility:** All buttons have ARIA labels
6. **Performance:** Lazy load action handlers
7. **Error Handling:** Show inline error messages
8. **Loading States:** Disable button during execution

---

**Status:** Design Complete  
**Ready for:** Component Implementation



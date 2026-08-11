---
name: affordance-driven-components
description: >-
  Enforces semantic component APIs, affordance-based naming, domain modeling over primitive obsession,
  strict state ownership, prop compression, and anti-god-component architecture for UI systems.
---

# Skill: affordance-driven-components

## Purpose & Philosophy

Design UI components around **user affordances** and **domain models**, not parent implementation mechanics.

This skill is a **framework-agnostic UI architecture guide** (applicable to React, Vue, Svelte, SwiftUI, Jetpack Compose, Flutter).

### The Architectural Hierarchy

1. **Model the domain first.** If values consistently travel together, extract a noun instead of passing unrelated primitives.
2. **Minimize the public API.** Expose the smallest meaningful surface via prop compression before splitting components.
3. **Separate state ownership.** Parents own business/data state; components own presentation and interaction state.
4. **Expose affordances, not implementation details.** Favor APIs like `upload`, `change`, or `clear` over `setX`, `openX`, or `handleX`.
5. **Split by responsibility only after the API is clean.** Component decomposition should follow clear ownership boundaries, not arbitrary line count.

---

# Core Rules & Principles

## 1. Missing Noun Detection & Primitive Obsession

**Rule:** If multiple props always travel together, they represent a domain noun. Do not pass loose primitives.

### ❌ Primitive Obsession
```tsx
// Bad: 3 loose primitives representing a single timeframe
interface Props {
  startDate: string;
  endDate: string;
  isCurrent: boolean;
}

// Bad: loose primitives representing contact details
interface Props {
  firstName: string;
  lastName: string;
  email: string;
  phone: string;
}
```

### ✅ Extracted Domain Nouns
```ts
// Good: Encapsulated concepts
interface Period {
  start: string;
  end: string;
  current: boolean;
}

interface Contact {
  name: string;
  email: string;
  phone: string;
}
```

```tsx
// Clean component interface
interface Props {
  period: Period;
  contact: Contact;
}
```

---

## 2. Separate Domain State from UI Presentation State

**Rule:** Business data state belongs to the parent. Presentation and interaction state belongs to the component.

| State Type | Owned By | Examples | Location |
| :--- | :--- | :--- | :--- |
| **Business / Domain State** | Parent | `user`, `period`, `resume`, `experience`, API loading | Parent store / page state |
| **Presentation / UI State** | Component | `showModal`, `showPicker`, `activeTab`, `expanded`, `hovered`, `pickerYear` | Component hooks (`useModal()`, `usePicker()`) |

### ❌ Leaked UI State in Parent Interface
```tsx
// Bad: Parent managing child UI internal details
interface Props {
  showModal: boolean;
  showPicker: boolean;
  activeTab: string;
  pickerYear: number;
}
```

### ✅ Internalized Presentation State
```tsx
// Good: Component manages UI interaction internally via hooks
export function DateInputs({ period, change }: Props) {
  const { open, toggle } = usePicker(); // Managed inside component
  const { year, step } = useCalendar(); // Managed inside component
  // ...
}
```

---

## 3. The "Manager Smell" & Interaction Ownership

**Rule:** The parent owns data. The child owns interaction.

When a parent component passes low-level mechanical controllers (`open()`, `close()`, `show`, `hide`, `setX()`, `toggle()`, `activate()`), the parent is acting as a **Manager middleman**.

### ❌ Manager Middleman
```tsx
interface Props {
  openStart: () => void;
  closeStart: () => void;
  setStartDate: (val: string) => void;
  setShowPicker: (val: boolean) => void;
}
```

### ✅ Affordance Intent API
```tsx
interface Props {
  period: Period;
  change: (period: Period) => void;
}
```

---

## 4. Prop Compression Before Component Splitting

**Rule:** Optimize and compress the API surface *before* splitting files.

Follow this exact refactoring sequence:
```
Detect repeated primitives → Extract noun → Reduce props → Move UI state → Split components
```

### Example: Prop Surface Reduction (9 props → 2 props)

#### ❌ Before Compression (9 Props)
```tsx
<DatePickerInput
  startDate={start}
  endDate={end}
  isCurrent={current}
  errors={errors}
  showStartPicker={showStart}
  openStart={handleOpenStart}
  closeStart={handleCloseStart}
  pickerYear={year}
  setPickerYear={setYear}
/>
```

#### ✅ After Compression (2 Props)
```tsx
<DatePickerInput
  period={period}
  change={setPeriod}
/>
```

---

## 5. Components Are Not Event Routers

**Rule:** Component props describe affordances ("what can be done"), not parent reactions or DOM mechanics.

| Bad (Event Router / Mechanics) | Good (Affordance Vocabulary) |
| :--- | :--- |
| `onSelectFile`, `handleUpload` | `upload` |
| `onSubmitForm`, `handleSubmit` | `submit` |
| `onClickClose`, `handleCloseModal` | `close` |
| `onNavigateBack` | `back` |
| `onChoosePlan` | `choose` |

Avoid handler prefixes and mechanical verb prefixes: `handle*`, `on*`, `callback*`, `trigger*`, `execute*`, `process*`.

---

## 6. Naming Guidelines: Concise vs. Compound Clarity

**Rule:** Prefer concise single-word names. Allow compound names *only* when a single noun cannot express the concept without ambiguity.

### ✅ Concise Nouns (Preferred)
```
period, resume, user, year, picker, draft, upload, scratch, submit, close, back
```

### ⚠️ Acceptable Compounds (When Needed for Semantic Clarity)
```
activeTab, currentStep, selectedItem
```
*(Avoid forced minimalism like `active` when it creates ambiguity—"Active what?")*

### ❌ Verbose / Redundant (Avoid)
```
uploadFile, handleUploadFile, onUploadResume, selectedUploadOption, currentUserData
```

---

## 7. Component Boundaries & Line Limits

* **Max 150 lines per file:** Files > 150 lines signal mixed layout, SVGs, or uncompressed APIs.
* **`index.tsx` is the composer:** `index.tsx` answers "How are these pieces assembled?". It contains no heavy styling or inline SVG assets.
* **SVGs belong in `assets/`:** Store complex graphic assets in an `assets/` directory (e.g. `choice/assets/papers.tsx`).

---

## 8. Function Signatures, DTO Inheritance & Stateless Namespaces

**Rule:** Apply affordance principles and domain objects to pure functions and utility modules, not just UI components.

* **Function Signature Compression:** If a function takes >3 arguments or loose related primitives (e.g. `role`, `employer`, `remote`, `seed`, `language`), bundle them into a cohesive typed Domain DTO (`Profile`, `Query`). Avoid `any[]`.
* **DTO Inheritance:** When multiple Domain DTOs share core attributes, extract the foundational concept (`Profile`) and use interface inheritance (`interface Query extends Profile`).
* **Explicit Return Domain Interfaces:** Never return anonymous structural shapes (`{ tone: string; text: string }[]`). Always define and export an explicit Domain Noun Interface (`Summary`).
* **Namespaces over Agent Nouns:** Replace `*Engine`, `*Service`, or `*Manager` classes with semantic domain namespaces (`DomainNoun.verb(query)`). Purge legacy `get*` methods and `*Engine` wrappers completely.

### ❌ Mechanical Engine / Service
```ts
// Bad: Loose positional parameters + Agent Noun ("Engine") + anonymous return shape
export const SuggestionEngine = {
  getExperienceBullets: (pos: string, comp: string, remote: boolean, seed: number, lang: string) => { ... },
  getSummaryVariations: (pos: string, seed: number, lang: string): { tone: string; text: string }[] => { ... }
};
```

### ✅ Semantic Domain Namespace & DTO Hierarchy
```ts
// Good: Unified Profile & Query DTO hierarchy + explicit Summary entity
export interface Profile {
  role: string;
  employer: string;
  remote: boolean;
  seed: number;
  language: string;
}

export interface Query extends Profile {
  category: string;
  experiences: Experience[];
  education: Education[];
  selected: string[];
}

export interface Summary {
  tone: string;
  text: string;
}

export namespace Suggestion {
  export function bullets(profile: Profile): string[] { ... }
  export function summaries(profile: Profile): Summary[] { ... }
  export function pills(query: Query): string[] { ... }
}
```

---

## 9. Domain Noun Elevation & Variable Purification

**Rule:** Elevate technical or database variable names to rich domain vocabulary. Local variables and parameters must describe domain meaning—never implementation metadata (`Tag`, `Flags`, `Meta`), memory structures (`Pool`, `Set`, `List`), or boolean prefix noise (`is*`).

| ❌ Technical / Database Name | ❌ Implementation Metadata / Memory Leak | ✅ Elevated Domain Noun |
| :--- | :--- | :--- |
| `position` | `positionTitle` | `role` |
| `company` | `companyName`, `targetComp` | `employer` |
| `isRemote` | `remoteTag`, `isRemoteFlag` | `environment` or `remote` |
| `bulletsPools` | `rawPoolArray`, `expertPool` | `collections`, `expert` |
| `selectedSet` | `selectedArray` | `chosen` |
| `isFr` | `isFrench` | `french` |

---

# 📊 The API Smell Score (Component & Function Health Checklist)

Evaluate component and function quality using these smell indicators:

| Check | Metric / Smell | Weight |
| :--- | :--- | :--- |
| 1 | **Props / Function args count > 6?** | ⚠️ High Risk |
| 2 | **More than two booleans?** | ⚠️ Primitive Obsession |
| 3 | **More than three callbacks?** | ⚠️ Event Router Smell |
| 4 | **Any `setX` or `showX` prop?** | ⚠️ Leaking UI / State Setter |
| 5 | **Any `isOpen` / `isClosed` prop or `isX` local var?** | ⚠️ Mechanical State / Prefix Noise |
| 6 | **Agent Noun class/object (`*Engine`, `*Service`)?** | ⚠️ Middleman Smell |
| 7 | **Any `open/close` handler pair?** | ⚠️ Manager Smell |
| 8 | **Repeated primitive prefixes (`startDate`, `endDate`) or non-inherited DTOs?** | ⚠️ Missing Noun / Hierarchy |
| 9 | **Type-leaking variable suffixes (`*Set`, `*Pool`, `*Tag`)?** | ⚠️ Memory / Metadata Structure Leak |

### Evaluation Criteria

* **0 - 1 Warnings:** ✅ Excellent Affordance API & Clean Code
* **2 - 3 Warnings:** ⚠️ Needs Parameter / Variable Compression
* **4+ Warnings:** ❌ Architectural Fail: Re-model domain & internalize state

---

# Summary Checklist

Before declaring a component or function complete:

1. **Domain Model & Inheritance:** Did you extract cohesive nouns (`Profile`, `Query`, `Summary`) and use interface inheritance (`Query extends Profile`) where appropriate?
2. **Prop / Parameter Count:** Is the API parameter surface minimal?
3. **State Ownership & Namespaces:** Is UI interaction state kept inside the component, and are stateless helpers organized as namespaces (`Suggestion.bullets(profile)`) rather than Agent Nouns (`SuggestionEngine`)?
4. **Affordance API:** Do props and functions express natural English actions (`upload`, `submit`, `bullets`, `summaries`) rather than mechanical handlers (`handleX`, `getExperienceBullets`)?
5. **Domain Vocabulary Elevation:** Are local variable names elevated (`role`, `employer`, `environment`, `collections`) and free of `is*` prefixes, `*Tag` metadata, and `*Set`/`*Pool` memory type suffixes?
6. **Composition:** Is `index.tsx` acting as a clean composer under 150 lines?



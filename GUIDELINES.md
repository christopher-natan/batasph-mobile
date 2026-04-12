# GUIDELINES.md

## Imports

Always use package imports — never relative imports (`../`, `./`).

```dart
// correct
import 'package:navi/config/translations/strings_enum.dart';

// wrong
import '../../config/translations/strings_enum.dart';
```

---

## State Management

We use **GetX** for state management, dependency injection, and routing throughout the project.

---

## Global vs Module Scope

**The golden rule: if something is used by only one module, it belongs inside that module — not in a global folder.**

| Folder | Scope | Rule |
|---|---|---|
| `lib/components/` | Global | Only components shared across 2+ modules |
| `lib/services/` | Global | Only services shared across 2+ modules |
| `lib/utils/` | Global | Only utilities shared across 2+ modules — files named `*_util.dart` |
| `lib/pages/[module]/components/` | Module | Components used only within that module |
| `lib/pages/[module]/services/` | Module | Services used only within that module |

---

## Module Structure

Development follows a modular structure. Each feature has its own folder.

```
boarding/
  boarding_page.dart         # UI only
  boarding_controller.dart   # Logic and service calls only
  boarding_binding.dart      # GetX DI binding
  services/                  # Services used only within this module
  components/                # UI components used only within this module
```

- `*_page.dart` — UI only
- `*_controller.dart` — logic only, no UI code and no widget/component building (for example `Button`)
- `*_binding.dart` — GetX dependency injection

---

## Page → Component → Widget Hierarchy

The codebase follows a strict three-level hierarchy:

```
lib/pages/<page>/                                   ← PAGE (top-level route)
  <page>_page.dart
  <page>_controller.dart
  <page>_binding.dart
  services/                                         ← page-scoped services
  components/
    <component>_component.dart                      ← COMPONENT (single file, no logic)
    <component>/                                    ← COMPONENT (folder, has logic or sub-widgets)
      <component>_component.dart
      <component>_controller.dart
      widgets/
        <widget>/                                   ← WIDGET (always its own folder)
          <widget>_widget.dart
          <widget>_controller.dart                  ← only if widget has logic
```

**Rules:**

- A **page** is a full-screen route registered in `app_pages.dart`. Always has its own folder under `lib/pages/`.
- A **component** is a UI piece inside a page. Single file if no logic; promoted to a folder when it needs a controller or sub-widgets.
- A **widget** is a UI piece inside a component. Always lives in its own subfolder under `widgets/`, even if it is a single file.
- A full-screen route pushed via `Get.to()` or `Get.toNamed()` is a **page**, not a component or widget — it must be promoted to its own module under `lib/pages/`.

---

## Logic and Service Access

**UI files contain UI only.** No business logic in `*_page.dart`, `*_component.dart`, or `*_widget.dart`.

Any page, component, or widget that needs logic gets a sibling `*_controller.dart`:

| Level | UI file | Controller (if logic exists) |
|-------|---------|------------------------------|
| Page | `*_page.dart` | `*_controller.dart` |
| Component | `*_component.dart` | `*_controller.dart` |
| Widget | `*_widget.dart` | `*_controller.dart` |

**Service access is restricted:**

- Services may only be called from **controllers** or from **other services**.
- UI files must **never** import or call services directly.
- The flow is always: **UI → Controller → Service** (and Service → Service is allowed).

---

## Component Structure

A component with no controller is a single file directly in `components/`:

```
components/
  label_component.dart
  avatar_component.dart
```

A component with its own controller gets a folder:

```
components/
  location/
    location_component.dart
    location_controller.dart
```

If a component contains subcomponents used only by that component, create a `widgets/` folder inside the component:

```
components/
  location/
    location_component.dart
    location_controller.dart
    widgets/
      button/
        button_widget.dart
        button_controller.dart
```

- Anything inside `components/location/widgets/` is for `location_component.dart` only
- Every widget inside `widgets/` always gets its own folder, even if it only has `button_widget.dart`
- If that widget needs logic, add `button_controller.dart` in the same widget folder

---

## Never Silently Remove or Change Existing Functionality

**Before removing or changing any existing working behaviour, explicitly inform the user and get approval.**

This includes:
- Removing a feature or side effect (e.g. marker removal on disconnect)
- Changing what an event or action triggers
- Replacing one behaviour with another "better" one without asking
- Any refactor that alters observable app behaviour, even if the code looks cleaner

If the change has a trade-off, state the trade-off clearly so the user can decide.

---

## Think Before You Change

**Read and fully understand the existing code before making any change.**

- Investigate the root cause completely before writing a single line
- Never change working behaviour based only on a guess or hypothesis
- Do not make blind behaviour changes just to "try something" without confirmed evidence
- If the problem is minor or self-healing, do not intervene with unnecessary code
- Apply the smallest reliable change that solves the actual problem — nothing more
- Do not add complexity, abstractions, or new patterns unless strictly required
- Over-engineering breaks working code and creates debt that is harder to undo than the original problem

**When in doubt, ask first. A wrong fix is worse than no fix.**

Never guess. Every fix or implementation must be based on confirmed understanding of the code — not assumptions about what might be causing a problem. If the root cause is not fully understood, investigate further or ask the user before proceeding.

---

## Keep Implementation Straightforward

**Do not over-engineer a change in a way that risks or sacrifices working app functionality.**

- Prefer the most direct implementation that solves the real problem
- Do not add extra abstraction, state, indirection, or architectural cleanup unless it is clearly required
- Do not widen the scope of a fix when a narrow, reliable change is enough
- Working product behaviour takes priority over cleverness or "cleaner" theory

If a straightforward fix exists, use it.

---

## No Dirty Fixes

**We do not patch symptoms — we fix root causes.**

A dirty fix makes the problem invisible without solving it. It creates hidden debt that compounds over time and makes the codebase unreliable.

**A fix is dirty if it:**
- Masks the real failure instead of addressing why it happens
- Works around a bug in one place by adding compensating logic somewhere else
- Uses a timeout or delay to paper over a race condition instead of eliminating the race
- Truncates, reformats, or hides bad data instead of ensuring the data is correct at the source
- Adds a special case or flag to skip logic that should work correctly for everyone

**A fix is clean if it:**
- Addresses the root cause directly
- Leaves the code simpler or no more complex than before
- Would still be correct if all the other workarounds were removed
- Can be explained in one sentence without the word "just"

```dart
// dirty — hides bad data in the UI
final display = label.length > 20 ? 'Friend' : label; // what if it's a UUID?

// clean — ensure the name is always available at the source
client.emit('userLocation', { userId: member.userId, location: member.location, name: member.name });
```

---

## Error Handling

**Never use fallbacks to paper over missing required data.**

If a value must exist for the app to function correctly, treat its absence as a real failure — log it, surface it, and fix the root cause. Do not silently substitute a default or alternative value.

```dart
// wrong — hides the real problem
final userId = UsersModel.current?.userId ?? DeviceUtil.deviceId;

// correct — fail visibly so the root cause gets fixed
final userId = UsersModel.current?.userId;
if (userId == null) {
  NearbyRideLogger.error('User not loaded — cannot proceed');
  return;
}
```

---

## Service Structure

If a service grows large or contains multiple helper functions, add a `helpers/` folder to keep the service file clean:

```
services/
  database/
    database_service.dart
    helpers/
      connect_helper.dart
      error_helper.dart
```


# Preventive Maintenance App – Project Summary

_Last updated: 2025-08-21_

## Overview
Flutter + Firebase preventive maintenance (PM) application supporting Technician and Admin roles.

Key technologies:
- Firebase Auth for authentication
- Cloud Firestore for primary application data (equipment, checklist templates, checklist instances)
- Firebase Storage for image uploads (equipment photos, checklist images)
- GoRouter for declarative navigation and ShellRoute-based shells
- Freezed + json_serializable for immutable data models and (de)serialization

The current vertical slice implements: equipment CRUD, checklist template selection, checklist instance creation, and checklist execution (fill & submit) with image capture.

## Architecture snapshot

```
lib/
   main.dart                # App init, router config, role-based redirect (RoleGate), shells
   firebase_options.dart    # Generated Firebase config
   core/
      utils/timestamp_converter.dart
   data/
      models/                # Freezed data classes (equipment, checklist templates/instances, issues, history events, user profile)
      sources/               # Firestore repositories (equipment, template, instance)
      repositories/          # Interfaces / repository contracts
   services/
      auth_service.dart      # Sign-in, register, password reset, sign out
      storage_service.dart   # Image uploads (instances)
   screens/
      loginpage/             # splash, login (GoRouter), register (not yet fully refactored)
      tech/                  # equipment list/edit, template picker, checklist fill, tech home
      dashboard/             # legacy dashboards (user/admin) - partially replaced by shells
      dev/                   # template seeder / development utilities
```

## Navigation & routing
- GoRouter with a global auth redirect.
- Technician shell (`UserShell`) uses ShellRoute and provides bottom navigation: home (`/t/home`), equipment (`/t/equipment`), history (`/t/history` — stub).
- Full-screen flows (e.g., filling a checklist: `/t/fill/:instanceId`) live outside the shell so they appear modal/fullscreen.
- Equipment add/edit routes are admin-scoped (`/admin/equipment/...`).
- RoleGate reads `users/{uid}` for the `role` field and redirects to the appropriate shell (`/admin` or `/t/home`).
- Splash screen bootstraps auth state and delegates to RoleGate.

## Data model summary
(Fields inferred from code — Firestore collections currently used)

### equipment (collection: `equipment`)
- id (document id)
- name
- code
- location (nullable)
- images: [String] (download URLs)
- createdBy
- createdAt (Timestamp / serverTimestamp)
- updatedAt (Timestamp / serverTimestamp)

### checklist_templates (collection: `checklist_templates`)
- id
- title / name + tags
- schema (JSON; sections[] → fields[] where each field has key, label, type, required)
- createdAt / updatedAt

### checklist_instances (collection: `checklist_instances`)
- id
- templateId
- equipmentId
- status: draft | in_progress? | submitted (submission sets `submitted`)
- answers: map fieldKey → value (text / number / bool / date / url)
- images: [] (not heavily used in UI yet)
- assignees: [uid]
- dueDate (optional)
- createdBy
- createdAt / updatedAt / submittedAt

### users (collection: `users`)
- name, email, role (currently `user`/`admin`), phone, department

(Models for issue, history_event, and user_profile exist; some flows are not yet wired.)

## Repositories & services
- FirestoreEquipmentRepo: CRUD for equipment and image upload path `equipment/{equipmentId}/{timestamp}.{ext}`.
- FirestoreTemplateRepo: create/update templates with server timestamps.
- FirestoreInstanceRepo: create instances from templates, patch answers, attach images (URLs stored in answers), and submit instances.
- StorageService: uploads checklist/instance images under `instances/{instanceId}/{fieldKey}/`.
- AuthService: sign-in, register, reset password, sign out; Role information is read from the `users/{uid}` document.

## UI feature slice implemented
- Login (GoRouter, with animations). Register exists but may still use Navigator in places.
- Splash → RoleGate → Shell-based main flows.
- Equipment list (real-time stream), add/edit with image capture and multi-image selection.
- Template picker: lists templates and creates an instance when a template is selected.
- Dynamic checklist execution form: supports text, number, boolean, date and image fields; answers are patched incrementally.
- Checklist submit flow: submission sets a final status and locks the instance.

## Utility / dev
- Template seeder utility (dev page) for inserting sample templates.

## Not yet implemented / incomplete
- Firestore security rules are not included (risk: overly permissive writes).
- Offline mutation queue / advanced caching beyond Firestore's built-in persistence.
- Work order abstraction — checklist_instances are currently used directly as work objects.
- Role expansion and finer-grained permissions (supervisor, viewer, etc.).
- Inventory/parts management, scheduling automation (PM generation), FCM notifications, and reporting dashboards.
- History & issue creation flows: models exist but UI flows are incomplete.
- Unit and widget tests are mostly missing (only default test file present).
- Consistent error handling and loading states—some views lack robust UX around async ops.
- Client-side validation for required checklist fields and stronger schema enforcement.
- Centralized state management is not adopted (current mix of setState and streams).
- Duplicate screens: legacy `DashboardUserScreen` vs `UserShell`.
- Register screen may still use Navigator instead of GoRouter in parts.

## Code quality & architecture observations
Strengths
- Clean separation between repository layer and data models.
- Freezed & json_serializable are used for immutable models and (de)serialization.
- Incremental-save pattern for checklist answers reduces data-loss risk.
- ShellRoute usage scopes bottom navigation cleanly.

Gaps / risks
1. Mixed navigation (Navigator vs GoRouter) remains in some screens and can confuse back-stack semantics.
2. Firestore security rules are not present in the repo (important to add before production use).
3. No explicit Work Order abstraction — checklist_instances double as work objects.
4. Limited domain/use-case separation; UI often orchestrates repository calls directly.
5. No global error boundary / centralized logging visible (Crashlytics dependency appears present but integration is unclear).
6. Storage path patterns differ between equipment and instances; deletion/cleanup flows are not handled.
7. Date handling mixes client DateTimes and server timestamps; ensure consistent timestamp strategy.
8. Required-field validation for checklists is minimal or missing.
9. RoleGate reads the user document at app start without caching.
10. Tests are largely missing, increasing regression risk.
11. Template picker queries all templates without pagination or filters.
12. No structured audit logging for per-field changes.
13. No i18n/localization strategy; strings appear inline in mixed languages.
14. UI styling tokens are scattered rather than centralized.
15. Image upload UX lacks progress, retry, and deletion handling.

## Immediate improvement priorities (recommended)
1. Security rules (high priority)
   - Add Firestore rules that restrict writes by role and ownership (admins only for equipment, assignees/editors for instances, etc.).
2. Register screen: router refactor
   - Migrate remaining Navigator usage to GoRouter and use context.go/context.push consistently.
3. Enforce required checklist fields
   - Validate required fields on the client and block submission until satisfied.
4. Use explicit role strings
   - Prefer `technician` | `admin` (or an enum) to avoid the ambiguous `user` label.
5. Introduce a lightweight Work Order abstraction
   - Wrap checklist_instance with scheduling metadata (priority, dueDate, lifecycle transitions).
6. Improve error & loading UX
   - Centralize loading/error widgets and use them consistently.
7. Extract design tokens / theme constants
   - Centralize colors, spacing, typography.
8. Add repository unit tests
   - Target equipment CRUD, instance patch/submit, and template create flows.

## Next wave enhancements
9. Offline mutation queue — persist pending patches and replay on reconnect.
10. Image management — deletion, compression, progress UI, and retry.
11. Notifications (FCM) — assignment, due reminders, submission confirmations.
12. Admin KPIs — overdue counts, completion rates, upcoming tasks.
13. Scheduling automation — generate PM instances from template frequency (Cloud Functions).
14. Parts / inventory module — track parts used during maintenance.
15. Audit trail collection — activity logs with per-field change records.
16. Pagination & query optimization — avoid unbounded listeners; add relevant indexes.
17. Localization (i18n) — extract strings and add ARB/localization pipeline.
18. Accessibility pass — semantic labels and larger tap targets.

## Suggested folder evolution
```
lib/
   core/
      config/theme/
      errors/
      widgets/ (loading, error, empty states)
   features/
      auth/
      equipment/
      checklist/
      work_orders/
      dashboard/
      admin/
```

## Technical debt quick wins (1-day)
- Refactor the Register screen navigation to use GoRouter.
- Add client-side required-field validation and a schema flag check before submit.
- Draft `lib/security/firestore.rules.md` describing intended Firestore rules as a first step.
- Introduce `AppColors` and `AppSpacing` constants.
- Add a simple Result/Either wrapper for repository and auth error handling.

## Firestore rule skeleton (documentation)
```js
// Pseudo outline
match /databases/{db}/documents {
   function isSignedIn() { return request.auth != null; }
   function isAdmin() { return isSignedIn() && get(/databases/$(db)/documents/users/$(request.auth.uid)).data.role == 'admin'; }

   match /users/{uid} {
      allow read: if isSignedIn() && (request.auth.uid == uid || isAdmin());
      allow write: if isAdmin() || request.auth.uid == uid; // self updates limited
   }
   match /equipment/{id} {
      allow read: if isSignedIn();
      allow create, update, delete: if isAdmin();
   }
   match /checklist_templates/{id} {
      allow read: if isSignedIn();
      allow write: if isAdmin();
   }
   match /checklist_instances/{id} {
      allow read: if isSignedIn();
      // allow update if the requester is an assignee or an admin. Adjust for multi-assignee logic as needed.
      allow update: if isSignedIn() && (isAdmin() || (request.auth.uid in resource.data.assignees));
      allow create: if isSignedIn();
      allow delete: if isAdmin();
   }
}
```
(Adjust logic for multi-assignee and field-level restrictions.)

## Summary
This repo contains a solid vertical slice (equipment CRUD + checklist execution) with modern Flutter + Firebase tooling. Prioritize hardening (Firestore rules, validation), finishing navigation consistency, and introducing small domain abstractions (work orders) and design tokens before expanding into scheduling, inventory, and reporting.

---

Changelog for this document (2025-08-21):
- Updated last-updated date.
- Minor wording and structural clarifications for readability.
- Slightly more precise Firestore rule example for multi-assignee handling.

If you'd like, I can now:
- create the `lib/security/firestore.rules.md` draft mentioned above,
- or open a PR that adds `AppColors`/`AppSpacing` and a simple Result wrapper.
Indicate which you prefer and I'll implement it.

---
Generated summary – keep this file updated as architecture evolves.

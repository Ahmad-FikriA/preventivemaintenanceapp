# Improvement Plan

Priority tiers are grouped to deliver stability first, then usability, then scale & analytics.

## Tier 0 – Critical Hardening (Security & Consistency)
1. Firestore Security Rules
   - Implement role-based access (admin vs technician) per PROJECT_SUMMARY.md draft.
   - Add validation: `equipment.name` non-empty, restrict writable fields on instances (only answers & status by assignees).
2. Navigation Consistency
   - Refactor `register_screen.dart` to use GoRouter (replace Navigator calls).
   - Remove/replace legacy `DashboardUserScreen` if unused or integrate logout & menu there.
3. Required Checklist Validation
   - Before submit: compute missing required fields from template schema; if missing show dialog listing them.
4. Role Consistency
   - Normalize roles to `technician` & `admin`; migrate existing documents.
5. Error Handling Pattern
   - Create `AppErrorWidget`, `LoadingSpinner`, `EmptyState` reusable widgets.

## Tier 1 – Core Domain Maturity
6. Work Order Abstraction
   - Introduce `work_orders` collection referencing `checklist_instances` + scheduling metadata (dueDate, priority, status transitions, asset references).
7. Audit Trail
   - `activity_logs` collection capturing changes to answers & status (who, when, what changed). Add Cloud Function trigger (optional) or client-side writes.
8. Offline Support Enhancement
   - Explicit queue for answer patches (local list -> replay) + visual unsynced indicator.
9. Image Management Improvements
   - Delete unused images when user replaces them. Add compression (e.g., `image` package) before upload.
10. Theming / Design System
   - Centralize colors (AppColors), spacing (Gaps), text styles, gradients. Replace magic numbers.

## Tier 2 – Scheduling & Productivity
11. PM Template Frequencies
   - Extend template with `frequencyType` (days, meter, cron-like) and `interval`.
   - Cloud Function scheduled (via Firebase Scheduled Functions) to generate upcoming checklist instances/work orders.
12. Notifications (FCM)
   - Token collection, assignment notification, due soon, overdue escalation.
13. History & Issues
   - Implement issue creation from inside a checklist (flag field -> opens issue doc).
   - History timeline for equipment combining completed instances and issues.
14. Parts / Inventory (Initial)
   - Parts collection + usage logging on submit.

## Tier 3 – Reporting & Insights
15. Dashboard KPIs
   - Completion rate, overdue count, MTTR/MTBF once failure/issue model is in place.
16. CSV / PDF Export
   - Export a completed checklist instance and equipment history.
17. Advanced Filtering & Search
   - Query by equipment code, status, date range.

## Tier 4 – Quality & Scale
18. Unit & Widget Tests
   - Repos (mock Firestore), checklist form rendering, submit flow.
19. Performance & Query Optimization
   - Composite indexes for common filters; pagination (limit + startAfter) for equipment list & templates.
20. Localization & Accessibility
   - Extract strings to ARB; add semantics labels to icons/buttons.
21. Analytics
   - Event logging (screen views, submit events) via Firebase Analytics.

## Quick Wins (1-2 days)
- Register screen GoRouter refactor.
- Add logout action to UserShell (AppBar or Overflow menu).
- Add required checklist field validation.
- Introduce a `Result<T>` or `Either` style wrapper for repo operations.
- Document intended security rules (`docs/SECURITY_RULES_DESIGN.md`).

## Stretch Ideas
- QR/Barcode scan to open equipment detail.
- Signature capture field type.
- Conditional checklist fields (showIf answers.X == value).
- Dark mode theme.
- Predictive maintenance integration (placeholder analytics panel).

## Dependency Suggestions
- State management: Riverpod or Bloc to remove manual setState sprawl.
- Form validation: `flutter_form_builder` (optional) or custom light validator layer.
- Image compression: `image` package or `flutter_image_compress`.
- Result handling: `dartz` or lightweight custom sealed class.

## Metrics to Watch After Improvements
- Auth success vs failure rate.
- Average checklist completion time.
- Number of overdue work orders.
- Offline completion attempts queued.
- Crash-free sessions.

---
Iterate top-down; don’t start Tier 2 until Tier 0 & Tier 1 items are mostly green. Update this plan as architecture evolves.

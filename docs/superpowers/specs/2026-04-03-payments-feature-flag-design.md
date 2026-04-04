# Payments Feature Flag Design

**Date:** 2026-04-03  
**Status:** Approved

---

## Section 1: Flag Architecture

- Add `Rails.application.config.x.features.payments_enabled` backed by env var `PAYMENTS_ENABLED` (default: `true`).
- Expose helper methods available in controllers and views:
  - `payments_enabled?`
  - `payments_disabled?`
- The existing `self_hosted?` logic is untouched; the payment flag is independent and explicit.
- Toggle is runtime (app restart) with no database mutation required.

## Section 2: Behavior When Payments Are Disabled

**Subscription state semantics:**
- `Family#has_active_subscription?` returns `true` — all families treated as fully paid.
- `Family#needs_subscription?` returns `false` — no trial prompts.
- `Family#upgrade_required?` returns `false` — no upgrade gates.
- `Family#trialing?` returns `false` — suppresses trial banners and UI.

**Onboarding and access control:**
- `Onboardable#require_onboarding_and_upgrade` keeps standard onboarding checks but fully skips subscription and upgrade redirects when payments are disabled.
- Users always reach app functionality after completing onboarding, with no trial/upgrade detour.

**Payment endpoints and providers:**
- `SubscriptionsController` is fully feature-guarded when payments are disabled — all actions return 403.
- Stripe webhook endpoint `/webhooks/stripe` returns a benign `200 OK` no-op.
- No Stripe checkout, billing-portal, or checkout result calls execute while disabled.

**Navigation and pages:**
- All payment UI is hidden when disabled:
  - Billing link in settings nav
  - Trial/upgrade progress card in app layout sidebar
  - Trial/upgrade onboarding CTAs and all payment-related copy
  - Direct navigation to subscription or billing pages redirects to `root_path`

## Section 3: Routes, View Sanitation, Rollout, and Testing

**Route-level handling:**
- Routes remain defined for reversibility.
- Controllers gate all actions behind `payments_disabled?`.
- `/subscription/*` and `settings/billing` redirect to `root_path` in disabled mode.
- `/webhooks/stripe` returns no-op `200 OK` without processing events.

**View sanitation:**
- When payments are disabled, all payment-labeled UI elements and copy are hidden:
  - Buttons/links: "Upgrade", "Billing", "Try … for 14 days", "Manage subscription", "Choose plan"
  - Banners/cards: trial countdown progress bar, subscription renewal notice
  - Page copy: text mentioning "trial", "subscription", "billing", "payment", "credit card"
- Applies to: settings nav, layout sidebar, onboarding trial step, upgrade page, billing page, onboarding nav steps.

**Re-enable behavior:**
- Toggle on restores all original flows, routes, and UI with no data migration required.
- Existing subscription records are never modified.

**Testing strategy:**
- Tests with `with_payments_enabled(false)` stubs across:
  - Model/concern behavior (`upgrade_required?`, `needs_subscription?`, `has_active_subscription?`, `trialing?`)
  - Onboarding redirect behavior (no payment redirect when disabled)
  - Subscription/billing endpoints return 403 or redirect when disabled
  - Stripe webhook returns `200 OK` no-op when disabled
  - View assertions that payment text/buttons are absent when disabled

**Safety constraints:**
- No destructive DB updates.
- No subscription state rewrites.
- Purely runtime-flag behavior; rollback is instant (restart with flag set to `true`).

# Chrome DevTools Frontend Navigation Test Plan Design

**Date:** 2026-04-05
**Project:** Kuria (Maybe fork)
**Scope:** Authenticated in-app flows only (post-login)
**Objective:** Comprehensive DevTools-driven walkthrough of all major UI features

---

## Overview

This design specifies an executable Chrome DevTools test plan that systematically exercises every major authenticated page and feature in Kuria. The plan enables an LLM agent (or human tester) to:

1. Navigate through the application using real UI interactions
2. Validate page functionality and behavior
3. Capture console errors and network failures
4. Document defects with evidence

The approach prioritizes real-user paths over API-only testing, ensuring we catch UI-specific issues like JavaScript errors, rendering problems, and interaction bugs.

---

## Scope Definition

### In Scope (Authenticated Only)

Pages and flows accessible after login:

- **Dashboard** (`/`) - Main landing page with summary widgets
- **Accounts** (`/accounts`, account detail pages, new/edit flows) - All account types (depository, investment, property, vehicle, crypto, loan, credit card, other assets/liabilities)
- **Transactions** (`/transactions`) - Search, filters, bulk selection, creation
- **Transfers** (via transaction modal) - Inter-account transfers
- **Categories** (`/categories`) - CRUD operations, duplicate validation
- **Tags** (`/tags`) - CRUD operations
- **Merchants** (`/family_merchants`) - CRUD operations
- **Imports** (`/imports`, `/imports/new`, wizard flows) - Transaction, trade, account, Mint imports
- **Budgets** (`/budgets/:month_year`) - Monthly budget tracking
- **Investments** (holdings, trades, valuations) - Portfolio management
- **Chats** (`/chats`) - AI assistant sidebar (when enabled)
- **Settings** (`/settings/*`) - Profile, preferences, security, API keys, hosting, billing
- **Utility Pages** (`/changelog`, `/feedback`)

### Out of Scope

- Authentication flows (signup, login, password reset, MFA)
- Onboarding wizard (`/onboarding/*`)
- Admin-only pages (`/sidekiq`, `/design-system`)
- API-only endpoints (documented but not UI-tested)

---

## Execution Strategy

### Phase 1: Authentication Bootstrap

**Goal:** Establish authenticated session and verify shell is ready.

**Steps:**
1. Navigate to login page (via DevTools)
2. Fill credentials (seed user: `user@maybe.local` / `password`)
3. Submit login form
4. Verify redirect to root dashboard
5. Assert authenticated shell visible (sidebar, user menu, navigation)

**Validation Criteria:**
- URL shows `/` (root/dashboard)
- Page contains `[data-testid="user-menu"]` or equivalent
- No console errors during login
- Network request to `/sessions` succeeds (200)

### Phase 2: Global Navigation Sweep

**Goal:** Visit every major page via real UI navigation, validating page identity and health.

**Approach:**
- For each destination, navigate via sidebar/menu clicks (not direct URL)
- After each navigation, validate:
  - URL matches expected route
  - Page title/header is correct
  - Key container elements present
  - Console has no errors
  - No failed network requests

**Pages to Sweep (in order):**

1. Dashboard (`/`)
2. Accounts list (`/accounts`)
3. Transactions (`/transactions`)
4. Budgets (`/budgets` with current month)
5. Categories (`/categories`)
6. Tags (`/tags`)
7. Merchants (`/family_merchants`)
8. Imports (`/imports`)
9. Settings → Profile (`/settings/profile`)
10. Settings → Preferences (`/settings/preferences`)
11. Chats (via sidebar, when AI enabled)
12. Changelog (`/changelog`)
13. Feedback (`/feedback`)

### Phase 3: Feature-Depth Flows (High-Risk)

**Goal:** Exercise complex user flows beyond simple navigation.

#### Accounts Flow
1. Open "New account" modal from accounts page
2. Select "Depository" account type
3. Fill account name, balance
4. Create account
5. Verify appears in account list
6. Click account to view detail
7. Edit account name
8. Verify persistence

#### Transactions Flow
1. Search for a transaction by name
2. Apply account filter
3. Apply category filter
4. Clear filters
5. Create new transaction
6. Verify appears in list

#### Transfers Flow
1. Click "New transaction"
2. Select "Transfer"
3. Select source and destination accounts
4. Enter amount and date
5. Create transfer
6. Verify appears in activity grouped by date

#### Categories Flow
1. Navigate to categories
2. Click "New category"
3. Fill category name
4. Create category
5. Verify appears in list
6. Attempt duplicate creation
7. Verify validation error

#### Tags Flow
1. Navigate to tags
2. Create new tag
3. Verify appears in list

#### Imports Flow
1. Navigate to imports
2. Click "Import transactions"
3. Select "Copy & Paste" tab
4. Paste minimal valid CSV
5. Upload and proceed through wizard
6. Validate each step renders correctly:
   - Configuration (column mapping)
   - Category assignment
   - Tag assignment (if applicable)
   - Account assignment
   - Confirm/publish

#### Investments Flow
1. Navigate to investment account
2. Switch to "Activity" tab
3. Click "New transaction" → "Buy"
4. Enter ticker, date, quantity, price
5. Submit trade
6. Verify appears in activity
7. Switch to "Holdings" tab
8. Verify holding updated

#### Chats Flow (AI-enabled)
1. Open chat sidebar
2. If consent needed, verify consent UI
3. Create new chat
4. Send message
5. Verify message appears
6. Navigate back to chat index
7. Reopen chat
8. Verify message history persists

#### Settings Flow
1. Open user menu → Settings
2. Visit each settings subsection:
   - Profile (verify user info editable)
   - Preferences (verify locale/currency/date format/theme)
   - Security (verify MFA options if visible)
   - API Key (verify key management)
3. If self-hosted mode: visit Hosting settings

### Phase 4: Resilience Checks

**Goal:** Verify state persistence and basic responsiveness.

1. **Page Reload Test:**
   - Reload dashboard, verify no errors
   - Reload transactions with active filters, verify filters persist (if expected)
   - Reload settings page, verify form state

2. **Mobile Viewport Spot-Check:**
   - Emulate mobile viewport (375x667)
   - Verify dashboard renders without layout breaks
   - Verify transactions list scrolls correctly
   - Verify hamburger menu/navigation accessible

### Phase 5: Evidence Capture

**For Each Test Block:**

**Pass Criteria:**
- Navigation succeeds (no 404/500)
- Page renders expected content
- No console errors
- No failed network requests
- User interactions complete successfully

**On Failure:**
- Capture screenshot (`take_screenshot`)
- Capture console messages (`list_console_messages`)
- Capture failed network requests (`list_network_requests`, then `get_network_request` for specific failures)
- Record reproduction steps
- Document observed vs expected behavior

---

## DevTools Instrumentation Standards

### Before Each Interaction:
- `take_snapshot` to capture DOM state

### After Each Page Load:
- `list_console_messages` (filter: `error`, `warn`)
- `list_network_requests` (inspect non-2xx/3xx)

### On Interaction Failure:
- `take_screenshot` (save to test evidence folder)
- `get_network_request` for specific failed request details
- `get_console_message` for specific error details

### Viewport Testing:
- Use `resize_page` for responsive checks
- Default: `1440x900` (desktop)
- Mobile spot-check: `375x667`

---

## Defect Triage Model

**Blocker:**
- Cannot complete critical path (login, view dashboard, create transaction)
- Page crash or infinite loading
- Data corruption or security issue
- Console errors preventing functionality

**Major:**
- Feature works but with incorrect behavior
- Data display issues (wrong amounts, missing records)
- Broken sub-flows (filters don't apply, edits don't persist)
- Accessibility issues blocking screen reader users

**Minor:**
- Visual inconsistencies
- Copy/text issues
- Non-blocking warnings in console
- Slow load times without breakage
- Missing analytics/tracking events

**Known-Environment Exclusions:**
- Third-party API failures when env vars absent (e.g., OpenAI, Plaid, Stripe)
- Features behind feature flags that are intentionally disabled
- Self-hosted vs SaaS differences (document but don't flag as defects)

---

## Deliverables Format

### 1. Run Metadata
```
Test Run: [Timestamp]
Commit SHA: [Git commit]
Environment: [local dev / staging / production]
Test User: [user@maybe.local]
AI Enabled: [true/false]
Self-Hosted Mode: [true/false]
```

### 2. Coverage Table
```
| Page/Feature | Status | Notes |
|-------------|--------|-------|
| Dashboard | Pass | No issues |
| Accounts List | Pass | No issues |
| Create Account | Pass | Depository created successfully |
| Transactions | Fail | Filter persistence broken after reload |
| ... | ... | ... |
```

### 3. Issue Log
```
| Severity | Route | Description | Repro Steps | Evidence |
|----------|-------|-------------|-------------|----------|
| Blocker | /transactions | Search returns 500 | 1. Login 2. Navigate to transactions 3. Type "test" | screenshot_001.png, console_error_001.txt |
| Major | /accounts | Account balance not updating | 1. Edit account 2. Change balance 3. Save | screenshot_002.png |
```

### 4. Go/No-Go Statement
```
Release Confidence: [High/Medium/Low]
Blockers: [0/1/n]
Major Issues: [0/1/n]
Recommendation: [Proceed with release / Fix blockers first / Additional testing needed]
```

---

## Implementation Notes

### Test Data Requirements
- Seed user must exist with known credentials
- Demo data helpful but not required (tests can create their own data)
- For imports: valid CSV fixtures in `test/fixtures/files/imports/`

### Environment Dependencies
- `SELF_HOSTED` flag affects visible settings pages
- `OPENAI_ACCESS_TOKEN` enables chat flows (skip if absent)
- `SYNTH_API_KEY` enables securities data (optional)

### Known System Test Coverage
Current system tests in `test/system/` provide baseline:
- `onboardings_test.rb` - Skip (out of scope)
- `accounts_test.rb` - Account creation/editing flows
- `transactions_test.rb` - Search, filters, selection, bulk operations
- `transfers_test.rb` - Transfer creation
- `categories_test.rb` - Category CRUD and validation
- `imports_test.rb` - Transaction, trade, account, Mint import flows
- `trades_test.rb` - Buy/sell trade creation
- `settings_test.rb` - Settings navigation and self-hosting options
- `chats_test.rb` - Chat sidebar flows (AI-enabled)

This DevTools plan extends beyond system tests to:
- Console/network health monitoring
- Visual regression detection
- Responsive layout validation
- Full navigation matrix coverage

---

## Next Steps

After design approval, the implementation plan will specify:
1. Exact DevTools command sequences for each test
2. Expected DOM selectors and content assertions
3. Failure handling and evidence capture commands
4. Aggregation and reporting format

---

**Document Status:** Awaiting user approval before implementation plan creation

# Payments Feature Flag Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a single feature flag that fully disables payment/subscription functionality, treats all accounts as paid for app access, and removes all visible billing/subscription UI text when disabled, with clean re-enable behavior.

**Architecture:** Introduce one env-backed app flag (`payments_enabled`) and route all payment decisions through helper methods used by models/controllers/views. Keep subscription data untouched; behavior switches at runtime (app restart for env/config changes). Disable payment endpoints and Stripe webhook processing while preserving non-payment features.

**Tech Stack:** Ruby on Rails 8, Minitest, existing concerns/helpers pattern, Stripe provider integration.

---

## File structure and responsibilities

- `config/application.rb` — Define `config.x.features.payments_enabled` from env.
- `app/controllers/concerns/payment_featureable.rb` (new) — Provide `payments_enabled?` / `payments_disabled?` to controllers and views.
- `app/controllers/application_controller.rb` — Include `PaymentFeatureable`.
- `app/models/family/subscribeable.rb` — Centralize "treat as paid" behavior when payments disabled.
- `app/controllers/concerns/onboardable.rb` — Skip trial/upgrade redirect logic when payments disabled.
- `app/controllers/subscriptions_controller.rb` — Hard-disable subscription flow when payments disabled.
- `app/controllers/settings/billings_controller.rb` — Block billing page when payments disabled.
- `app/controllers/webhooks_controller.rb` — Make `stripe` action no-op when payments disabled.
- `app/views/layouts/application.html.erb` — Hide trial/upgrade banner.
- `app/views/settings/_settings_nav.html.erb` — Hide Billing nav item.
- `app/helpers/settings_helper.rb` — Hide Billing in footer-adjacent list.
- `app/views/onboardings/_onboarding_nav.html.erb` — Remove payment step when payments disabled.
- `app/views/onboardings/goals.html.erb` — Redirect onboarding flow to home (not trial) when payments disabled.
- `app/views/onboardings/trial.html.erb` — Hide/neutralize all payment/subscription messaging and CTAs when disabled.
- `app/views/subscriptions/upgrade.html.erb` — Defensive guard fallback content or redirect path support.
- `app/views/settings/billings/show.html.erb` — Defensive guard fallback content or redirect path support.
- `test/test_helper.rb` — Add helper for toggling payments flag in tests.
- `test/models/family/subscribeable_test.rb` — Verify paid semantics when flag disabled.
- `test/controllers/concerns/onboardable_test.rb` — Verify no payment redirects when disabled.
- `test/controllers/subscriptions_controller_test.rb` — Verify subscription endpoints are disabled when flag off.
- `test/controllers/settings/billings_controller_test.rb` — Verify billing page unavailable when flag off.
- `test/controllers/onboardings_controller_test.rb` — Verify trial page behavior/UI when payments disabled.

---

### Task 1: Feature flag plumbing (single source of truth)

**Files:**
- Create: `app/controllers/concerns/payment_featureable.rb`
- Modify: `app/controllers/application_controller.rb`
- Modify: `config/application.rb`
- Modify: `test/test_helper.rb`

- [ ] **Step 1: Add env-backed config in application config**

```ruby
# config/application.rb — add inside the Application class after the existing config.app_mode line
config.x.features = ActiveSupport::OrderedOptions.new
config.x.features.payments_enabled = ENV.fetch("PAYMENTS_ENABLED", "true") == "true"
```

- [ ] **Step 2: Create payment concern for controller/view access**

```ruby
# app/controllers/concerns/payment_featureable.rb
module PaymentFeatureable
  extend ActiveSupport::Concern

  included do
    helper_method :payments_enabled?, :payments_disabled?
  end

  private
    def payments_enabled?
      Rails.application.config.x.features.payments_enabled
    end

    def payments_disabled?
      !payments_enabled?
    end
end
```

- [ ] **Step 3: Include concern globally in ApplicationController**

In `app/controllers/application_controller.rb`, add `PaymentFeatureable` to the include list alongside the existing concerns.

- [ ] **Step 4: Add test helper to toggle flag safely**

```ruby
# test/test_helper.rb — add inside the ActiveSupport::TestCase module block
def with_payments_enabled(value)
  original = Rails.application.config.x.features.payments_enabled
  Rails.application.config.x.features.payments_enabled = value
  yield
ensure
  Rails.application.config.x.features.payments_enabled = original
end
```

- [ ] **Step 5: Run sanity check**

Run: `bin/rails test test/controllers/onboardings_controller_test.rb -n "/should get show/"`
Expected: PASS (no regressions from concern wiring)

- [ ] **Step 6: Commit**

```bash
git add config/application.rb app/controllers/concerns/payment_featureable.rb app/controllers/application_controller.rb test/test_helper.rb
git commit -m "feat: add payments feature flag plumbing"
```

---

### Task 2: Centralize "all users paid" behavior and access bypass

**Files:**
- Modify: `app/models/family/subscribeable.rb`
- Modify: `app/controllers/concerns/onboardable.rb`
- Modify: `app/views/onboardings/goals.html.erb`
- Modify: `app/views/onboardings/_onboarding_nav.html.erb`
- Modify: `test/models/family/subscribeable_test.rb`
- Modify: `test/controllers/concerns/onboardable_test.rb`

- [ ] **Step 1: Write failing model tests for disabled mode behavior**

```ruby
# test/models/family/subscribeable_test.rb
test "payments disabled treats family as active subscription" do
  with_payments_enabled(false) do
    assert @family.has_active_subscription?
    assert_not @family.needs_subscription?
    assert_not @family.upgrade_required?
    assert_not @family.trialing?
  end
end
```

- [ ] **Step 2: Run test to confirm it fails**

Run: `bin/rails test test/models/family/subscribeable_test.rb -n "/payments disabled/"`
Expected: FAIL

- [ ] **Step 3: Implement model behavior gates**

In `app/models/family/subscribeable.rb`, add a private `payments_enabled?` method that reads from `Rails.application.config.x.features.payments_enabled`, then gate the four methods:

```ruby
def upgrade_required?
  return false unless payments_enabled?
  return false if self_hoster?
  return false if subscription&.active? || subscription&.trialing?
  true
end

def trialing?
  return false unless payments_enabled?
  subscription&.trialing? && days_left_in_trial.positive?
end

def has_active_subscription?
  return true unless payments_enabled?
  subscription&.active?
end

def needs_subscription?
  return false unless payments_enabled?
  subscription.nil? && !self_hoster?
end

private
  def payments_enabled?
    Rails.application.config.x.features.payments_enabled
  end
```

- [ ] **Step 4: Run test to confirm it passes**

Run: `bin/rails test test/models/family/subscribeable_test.rb`
Expected: PASS

- [ ] **Step 5: Write failing onboarding redirect test**

```ruby
# test/controllers/concerns/onboardable_test.rb
test "onboarded user can visit dashboard when payments disabled and no subscription" do
  @user.update!(onboarded_at: 1.day.ago)
  with_payments_enabled(false) { get root_path }
  assert_response :success
end
```

- [ ] **Step 6: Run test to confirm it fails**

Run: `bin/rails test test/controllers/concerns/onboardable_test.rb -n "/payments disabled/"`
Expected: FAIL

- [ ] **Step 7: Implement onboarding redirect bypass**

In `app/controllers/concerns/onboardable.rb`, wrap the `needs_subscription?` and `upgrade_required?` checks so they are only evaluated when payments are enabled. Since those methods now return `false` when payments are disabled (Task 2 Step 3), the redirect conditions will evaluate to false automatically. No code change is strictly needed in `onboardable.rb` itself — verify by running the test.

If the test still fails, explicitly guard in `require_onboarding_and_upgrade`:

```ruby
elsif Current.family.needs_subscription?
  redirect_to trial_onboarding_path
elsif Current.family.upgrade_required?
  redirect_to upgrade_subscription_path
```

These already route through the model methods which now check the flag, so no `payments_enabled?` check is required here directly. Run the test to confirm.

- [ ] **Step 8: Remove payment-step progression in onboarding flow views**

```erb
<!-- app/views/onboardings/goals.html.erb, line with redirect_to hidden field -->
<%= form.hidden_field :redirect_to, value: (self_hosted? || payments_disabled?) ? "home" : "trial" %>
```

```erb
<!-- app/views/onboardings/_onboarding_nav.html.erb, the steps.pop line -->
<% steps.pop if self_hosted? || payments_disabled? %>
```

- [ ] **Step 9: Run all related tests**

Run: `bin/rails test test/models/family/subscribeable_test.rb test/controllers/concerns/onboardable_test.rb`
Expected: PASS

- [ ] **Step 10: Commit**

```bash
git add app/models/family/subscribeable.rb app/controllers/concerns/onboardable.rb app/views/onboardings/goals.html.erb app/views/onboardings/_onboarding_nav.html.erb test/models/family/subscribeable_test.rb test/controllers/concerns/onboardable_test.rb
git commit -m "feat: bypass subscription gating when payments disabled"
```

---

### Task 3: Disable payment endpoints and Stripe processing

**Files:**
- Modify: `app/controllers/subscriptions_controller.rb`
- Modify: `app/controllers/settings/billings_controller.rb`
- Modify: `app/controllers/webhooks_controller.rb`
- Modify: `test/controllers/subscriptions_controller_test.rb`
- Modify: `test/controllers/settings/billings_controller_test.rb`
- Modify: `test/controllers/webhooks_controller_test.rb` (file exists: create if needed)

- [ ] **Step 1: Write failing controller tests**

```ruby
# test/controllers/subscriptions_controller_test.rb
test "all subscription endpoints disabled when payments disabled" do
  with_payments_enabled(false) do
    get upgrade_subscription_path
    assert_response :forbidden
  end
end
```

```ruby
# test/controllers/settings/billings_controller_test.rb
test "billing page redirects to root when payments disabled" do
  sign_in users(:family_admin)
  with_payments_enabled(false) { get settings_billing_path }
  assert_redirected_to root_path
end
```

Locate `test/controllers/webhooks_controller_test.rb` or create it:
```ruby
# test/controllers/webhooks_controller_test.rb
require "test_helper"

class WebhooksControllerTest < ActionDispatch::IntegrationTest
  test "stripe webhook returns ok no-op when payments disabled" do
    with_payments_enabled(false) do
      post "/webhooks/stripe"
      assert_response :success
    end
  end
end
```

- [ ] **Step 2: Run tests to confirm they fail**

Run: `bin/rails test test/controllers/subscriptions_controller_test.rb -n "/payments disabled/" && bin/rails test test/controllers/settings/billings_controller_test.rb && bin/rails test test/controllers/webhooks_controller_test.rb`
Expected: FAIL

- [ ] **Step 3: Guard subscription controller**

```ruby
# app/controllers/subscriptions_controller.rb
# Change existing guard line from:
guard_feature if: -> { self_hosted? }
# To:
guard_feature if: -> { self_hosted? || payments_disabled? }
```

- [ ] **Step 4: Guard billing page**

```ruby
# app/controllers/settings/billings_controller.rb
class Settings::BillingsController < ApplicationController
  layout "settings"

  before_action :redirect_if_payments_disabled

  def show
    @family = Current.family
  end

  private
    def redirect_if_payments_disabled
      redirect_to root_path if payments_disabled?
    end
end
```

- [ ] **Step 5: Make Stripe webhook inert in disabled mode**

```ruby
# app/controllers/webhooks_controller.rb, inside the stripe action, add as first line:
def stripe
  return head :ok if payments_disabled?
  # ... rest of existing code
end
```

- [ ] **Step 6: Run tests to confirm they pass**

Run: `bin/rails test test/controllers/subscriptions_controller_test.rb test/controllers/settings/billings_controller_test.rb test/controllers/webhooks_controller_test.rb`
Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add app/controllers/subscriptions_controller.rb app/controllers/settings/billings_controller.rb app/controllers/webhooks_controller.rb test/controllers/subscriptions_controller_test.rb test/controllers/settings/billings_controller_test.rb test/controllers/webhooks_controller_test.rb
git commit -m "feat: disable subscription and stripe payment endpoints when payments disabled"
```

---

### Task 4: Remove all visible payment/subscription mentions from UI when disabled

**Files:**
- Modify: `app/views/settings/_settings_nav.html.erb`
- Modify: `app/helpers/settings_helper.rb`
- Modify: `app/views/layouts/application.html.erb`
- Modify: `app/views/onboardings/trial.html.erb`
- Modify: `app/views/subscriptions/upgrade.html.erb`
- Modify: `app/views/settings/billings/show.html.erb`
- Modify: `test/controllers/onboardings_controller_test.rb`

- [ ] **Step 1: Write failing view assertion test**

```ruby
# test/controllers/onboardings_controller_test.rb
test "trial page hides payment and subscription copy when payments disabled" do
  sign_in users(:family_admin)
  with_payments_enabled(false) { get trial_onboarding_url }
  assert_response :success
  assert_no_match(/subscription|upgrade|credit card/i, response.body)
end
```

Run: `bin/rails test test/controllers/onboardings_controller_test.rb -n "/hides payment/"`
Expected: FAIL

- [ ] **Step 2: Hide billing entry in settings nav**

```erb
<!-- app/views/settings/_settings_nav.html.erb -->
{ label: t(".billing_label"), path: settings_billing_path, icon: "circle-dollar-sign", if: !self_hosted? && payments_enabled? }
```

- [ ] **Step 3: Hide billing in settings helper footer list**

```ruby
# app/helpers/settings_helper.rb
# Change:
{ name: "Billing", path: :settings_billing_path, condition: :not_self_hosted? },
# To:
{ name: "Billing", path: :settings_billing_path, condition: :billing_available? },

# Add private method:
def billing_available?
  !self_hosted? && payments_enabled?
end
```

The `payments_enabled?` helper is available in views/helpers because it is defined as a `helper_method` in `PaymentFeatureable` which is included in `ApplicationController`.

- [ ] **Step 4: Hide trial/upgrade sidebar banner in layout**

```erb
<!-- app/views/layouts/application.html.erb -->
<!-- Change: -->
<% if Current.family.trialing? && !self_hosted? %>
<!-- To: -->
<% if payments_enabled? && Current.family.trialing? && !self_hosted? %>
```

- [ ] **Step 5: Sanitize trial page copy and CTAs**

```erb
<!-- app/views/onboardings/trial.html.erb -->
<!-- Wrap the entire content div inside the page with a conditional: -->
<% if payments_disabled? %>
  <div class="grow flex flex-col gap-12 items-center justify-center">
    <div class="max-w-sm mx-auto flex flex-col items-center">
      <%= image_tag "logo-color.png", class: "w-16 mb-6" %>
      <p class="text-xl lg:text-3xl text-primary font-display font-medium">
        Your account is fully active.
      </p>
      <%= render DS::Link.new(text: "Continue", href: root_path, full_width: true) %>
    </div>
  </div>
<% else %>
  <!-- existing content unchanged -->
<% end %>
```

- [ ] **Step 6: Add defensive guard to upgrade page**

```erb
<!-- app/views/subscriptions/upgrade.html.erb -->
<!-- At the very top of the template, before existing content: -->
<% if payments_disabled? %>
  <%= redirect_to root_path %>
<% end %>
```

Note: This is a fallback since the controller already redirects. But use a Rails approach — wrap upgrade content in conditional:

```erb
<% if payments_disabled? %>
  <div class="flex justify-center items-center h-full">
    <%= render DS::Link.new(text: "Continue to app", href: root_path) %>
  </div>
<% else %>
  <!-- existing upgrade content -->
<% end %>
```

- [ ] **Step 7: Add defensive guard to billing page**

```erb
<!-- app/views/settings/billings/show.html.erb -->
<% if payments_disabled? %>
  <%= settings_section title: t(".subscription_title") do %>
    <p class="text-secondary">Billing is not enabled for this deployment.</p>
  <% end %>
<% else %>
  <!-- existing billing content -->
<% end %>
```

- [ ] **Step 8: Run tests**

Run: `bin/rails test test/controllers/onboardings_controller_test.rb`
Expected: PASS

- [ ] **Step 9: Commit**

```bash
git add app/views/settings/_settings_nav.html.erb app/helpers/settings_helper.rb app/views/layouts/application.html.erb app/views/onboardings/trial.html.erb app/views/subscriptions/upgrade.html.erb app/views/settings/billings/show.html.erb test/controllers/onboardings_controller_test.rb
git commit -m "feat: hide billing and subscription ui when payments disabled"
```

---

### Task 5: Regression pass and verification

- [ ] **Step 1: Run targeted tests for all touched files**

```bash
bin/rails test test/models/family/subscribeable_test.rb test/controllers/concerns/onboardable_test.rb test/controllers/subscriptions_controller_test.rb test/controllers/settings/billings_controller_test.rb test/controllers/onboardings_controller_test.rb test/controllers/webhooks_controller_test.rb
```

Expected: PASS all

- [ ] **Step 2: Run broader controller and model test suite**

```bash
bin/rails test test/controllers test/models/family/subscribeable_test.rb
```

Expected: PASS or only pre-existing failures unrelated to these changes

- [ ] **Step 3: Final commit for docs**

```bash
git add docs/superpowers/specs/2026-04-03-payments-feature-flag-design.md docs/superpowers/plans/2026-04-03-payments-feature-flag.md
git commit -m "docs: add payments feature flag design and implementation plan"
```

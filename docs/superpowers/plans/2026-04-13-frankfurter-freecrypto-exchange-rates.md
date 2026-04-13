# Frankfurter + FreeCryptoAPI Exchange Rates Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace LLM-based exchange-rate fetching with deterministic API providers: Frankfurter for fiat historical rates and FreeCryptoAPI (free tier) for crypto live snapshots, while persisting all fetched values in DB and returning explicit errors when historical crypto is unavailable.

**Architecture:** Keep `ExchangeRate` call sites unchanged and swap provider implementation behind `Provider::Registry`. Introduce a composite exchange-rate provider that routes fiat pairs to Frankfurter and crypto-involved pairs to FreeCryptoAPI. Persist fetched rows into `exchange_rates`; historical crypto requests not already in DB should return explicit provider errors.

**Tech Stack:** Ruby on Rails, Faraday, ActiveRecord `upsert_all`, Minitest.

---

### Task 1: Lock behavior with tests

**Files:**
- Create: `test/models/provider/frankfurter_exchange_rates_test.rb`
- Create: `test/models/provider/freecrypto_exchange_rates_test.rb`
- Modify: `test/models/exchange_rate_test.rb`
- Modify: `test/models/exchange_rate/importer_test.rb`

- [ ] Add failing tests for provider contract and importer behavior
- [ ] Verify tests fail for expected reasons
- [ ] Commit test-only changes

### Task 2: Implement providers

**Files:**
- Create: `app/models/provider/frankfurter_exchange_rates.rb`
- Create: `app/models/provider/freecrypto_exchange_rates.rb`
- Modify: `app/models/setting.rb`

- [ ] Implement Frankfurter provider with date-range support
- [ ] Implement FreeCrypto provider with today-only snapshot behavior
- [ ] Add `freecrypto_api_key` setting
- [ ] Make Task 1 tests pass
- [ ] Commit provider changes

### Task 3: Wire composite provider

**Files:**
- Create: `app/models/provider/composite_exchange_rates.rb`
- Modify: `app/models/provider/registry.rb`

- [ ] Route fiat/fiat to Frankfurter and crypto pairs to FreeCrypto
- [ ] Preserve `ExchangeRate::Provided` call sites
- [ ] Commit routing changes

### Task 4: Remove LLM FX path

**Files:**
- Delete: `app/models/provider/opencode_exchange_rates.rb`
- Delete: `test/models/provider/opencode_exchange_rates_test.rb`
- Modify: related tests that reference old provider

- [ ] Remove old OpenCode exchange-rate provider path
- [ ] Update references and tests
- [ ] Commit cleanup changes

### Task 5: Verify and document

**Files:**
- Modify: `README.md` (if config docs for provider env vars belong there)
- Modify: `compose.example.yml` (if env var examples belong there)

- [ ] Run test suites relevant to touched code
- [ ] Document free-tier crypto historical limitation
- [ ] Commit documentation updates

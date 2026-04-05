# Hybrid OpenCode Dev Environment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the repository work reliably in hybrid dev mode (Rails/Sidekiq local, DB/Redis/OpenCode in Docker) without requiring provider keys in the Rails app.

**Architecture:** Rails runs locally and calls OpenCode at `localhost:4096`. OpenCode runs in Docker and calls local Rails MCP via `host.docker.internal`. Model selection stays in-app (`provider/model` string), while provider authentication remains managed by OpenCode itself (`/provider`, `/config/providers`).

**Tech Stack:** Rails 8, Docker Compose, OpenCode Server HTTP API, Faraday, Minitest.

---

## File Structure

### Files modified:
- `compose.dev.yml` — Added `opencode` service with `extra_hosts` for hybrid networking
- `app/services/opencode_config_generator.rb` — Made MCP URL topology-aware via `OPENCODE_MCP_HOST` env var
- `test/services/opencode_config_generator_test.rb` — Added hybrid URL and key-optional tests
- `lib/tasks/opencode.rake` — New rake task for config generation
- `.env.development` — Added `OPENCODE_MCP_HOST` for hybrid dev
- `.env.example` — Clarified provider auth is managed by OpenCode, not Rails
- `docs/hosting/docker.md` — Added hybrid development section with troubleshooting
- `test/test_helper.rb` — Added `webmock/minitest` require (pre-existing gap)
- `test/models/provider/opencode/client_test.rb` — Fixed assertion mismatch (pre-existing bug)

---

## Completed Tasks

### Task 1: Add OpenCode service to hybrid compose
- Added `opencode` service to `compose.dev.yml` with `extra_hosts`, healthcheck, config volume mount
- Validated with `docker compose -f compose.dev.yml config`

### Task 2: Make OpenCode config generator topology-aware and key-optional
- Updated `from_settings` to use `OPENCODE_MCP_HOST` env var (default: `host.docker.internal`)
- Provider keys remain optional (empty hash generates valid config)
- Added tests for hybrid URL and key-optional behavior
- All 8 config generator tests pass

### Task 3: Add explicit config generation command for dev
- Created `lib/tasks/opencode.rake` with `opencode:config:generate` task
- Writes `.opencode/opencode.json` with MCP URL and auth header
- Verified output with correct `host.docker.internal` URL

### Task 4: Align environment contracts
- Added `OPENCODE_MCP_HOST=host.docker.internal` to `.env.development`
- Updated `.env.example` comments to clarify provider auth is OpenCode-managed
- No provider keys required in Rails env

### Task 5: Document hybrid workflow
- Added "Hybrid Development" section to `docs/hosting/docker.md`
- Includes step-by-step setup, verification checklist, and troubleshooting

### Task 6: End-to-end verification
- All 24 opencode-related tests pass (config generator, client, provider)
- Fixed pre-existing test issues (webmock import, assertion mismatch)
- Compose config validates successfully

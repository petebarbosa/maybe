# Currency Exchange Rate Fetching

## Overview

All exchange rates are sourced from a single external provider: **Synth Finance** (`https://api.synthfinance.com`). Rates are stored locally in the `exchange_rates` table and used by the `Money` class for currency conversion.

## Architecture Diagram

See `docs/maps/monetary_fetching.drawio` for the visual architecture diagram.

## Architecture Flow

```
┌──────────────────────────────────┐
│  ImportMarketDataJob (daily)     │
│  or Account::MarketDataImporter  │
│  (on-demand during sync)         │
└──────────────┬───────────────────┘
               │
               ▼
┌──────────────────────────────────┐
│  MarketDataImporter              │
│  - Determines required pairs     │
│    from entries & accounts       │
└──────────────┬───────────────────┘
               │
               ▼
┌──────────────────────────────────┐
│  ExchangeRate::Importer          │
│  - Fetches from Synth API        │
│  - 5-day buffer (weekends/etc)   │
│  - LOCF gapfilling               │
│  - Batch upsert (200/batch)      │
└──────────────┬───────────────────┘
               │
               ▼
┌──────────────────────────────────┐
│  Provider::Synth                 │
│  - Faraday HTTP client           │
│  - Bearer token auth             │
│  - /rates/historical             │
│  - /rates/historical-range       │
└──────────────┬───────────────────┘
               │
               ▼
┌──────────────────────────────────┐
│  Synth Finance API               │
│  api.synthfinance.com            │
└──────────────────────────────────┘
```

## Key Files

| File | Purpose |
|------|---------|
| `app/models/provider/synth.rb` | HTTP client for Synth API |
| `app/models/provider/registry.rb` | Provider registration (`:synth` only for exchange rates) |
| `app/models/provider/exchange_rate_concept.rb` | Interface: `Rate = Data.define(:date, :from, :to, :rate)` |
| `app/models/exchange_rate/importer.rb` | Core import logic: fetch, gapfill, upsert |
| `app/models/exchange_rate/provided.rb` | Mixin: `find_or_fetch_rate`, `import_provider_rates` |
| `app/models/exchange_rate.rb` | ActiveRecord model |
| `app/models/market_data_importer.rb` | Orchestrates all market data (securities + exchange rates) |
| `app/models/account/market_data_importer.rb` | On-demand import for a single account |
| `app/jobs/import_market_data_job.rb` | Daily scheduled job |
| `lib/money.rb` | `Money#exchange_to` — uses rates for conversion |
| `lib/money/currency.rb` | Currency definitions from `config/currencies.yml` |
| `db/migrate/20240209200924_create_exchange_rates.rb` | Schema: `base_currency`, `converted_currency`, `rate`, `date` |

## Configuration

| Env Var / Setting | Purpose |
|-------------------|---------|
| `SYNTH_API_KEY` | API key for Synth Finance |
| `Setting.synth_api_key` | Alternative (DB-backed setting) |
| `SYNTH_URL` | Override API base URL (default: `https://api.synthfinance.com`) |

## API Endpoints

### Single Rate
```
GET /rates/historical?date=YYYY-MM-DD&from=USD&to=EUR
```
Used by `Provider::Synth#fetch_exchange_rate` (single lookup).

### Batch Rates
```
GET /rates/historical-range?from=USD&to=EUR&start_date=...&end_date=...
```
Paginated. Used by `Provider::Synth#fetch_exchange_rates` (bulk import).

## Import Flow Details

### `ExchangeRate::Importer`

1. **Skip check**: If all rates exist in DB and `clear_cache: false`, returns early.
2. **Date range**: Fetches with a 5-day buffer beyond requested `end_date` to cover weekends/holidays.
3. **Gapfilling**: Uses LOCF (Last Observation Carried Forward) to fill missing dates.
4. **Upsert**: Batch inserts 200 records at a time into `exchange_rates`.
5. **End date normalization**: Normalizes to today in `America/New_York` timezone.

### Required Currency Pairs

Determined by `MarketDataImporter#required_exchange_rate_pairs`:
- **Entry-based**: Currencies in entries that differ from account currency.
- **Account-based**: Account currency → family currency (if foreign account).

### On-Demand vs Scheduled

| Trigger | Scope | Entry Point |
|---------|-------|-------------|
| Daily job (market close) | All users, all pairs | `MarketDataImporter` |
| Account sync | Single account's pairs | `Account::MarketDataImporter` |
| Runtime conversion | Single rate (fallback) | `ExchangeRate.find_or_fetch_rate` |

## Conversion: `Money#exchange_to`

```ruby
def exchange_to(other_currency, date: Date.current, fallback_rate: nil)
  # 1. Same currency → return self
  # 2. Look up rate: ExchangeRate.find_or_fetch_rate(from, to, date)
  # 3. If not found, use fallback_rate
  # 4. Raise ConversionError if no rate available
  # 5. Return Money.new(amount * rate, other_currency)
end
```

**Usage locations:**
- `app/models/balance/sync_cache.rb` — converting entries/holdings to account currency
- `app/models/holding/portfolio_cache.rb` — converting prices to account currency
- `app/models/transfer/creator.rb` — cross-currency transfers
- `app/components/UI/account/chart.rb` — displaying balance in family currency

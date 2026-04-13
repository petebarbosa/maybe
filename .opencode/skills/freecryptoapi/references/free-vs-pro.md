# FreeCryptoAPI: Free vs PRO Tier Reference

**Last Verified**: April 13, 2026  
**Test Method**: Live API calls with free tier API key  
**API Key Used**: `1sjgbputqqzki2ahew1w`

## Overview

FreeCryptoAPI has two tiers:
- **FREE**: 100,000 requests/month, 4 verified endpoints
- **PRO**: $19.99/month, 10,000,000 requests/month, 15+ additional endpoints

## Verified FREE Tier Endpoints (4 Total)

These endpoints were tested and confirmed working with a free API key:

| Endpoint | Description | Example Response | Notes |
|----------|-------------|------------------|-------|
| `/getData` | Live market data | `{"symbol":"BTC","last":"73078",...}` | Single or multiple symbols (BTC+ETH) |
| `/getCryptoList` | Supported cryptocurrencies | `{"status":true,"resultset_size":3101,...}` | Returns 3,101+ coins |
| `/getExchange` | Exchange-specific data | `{"status":"success","symbols":[...]}` | Tested with binance |
| `/getConversion` | Crypto conversion | `{"result":32.47}` | **Crypto-to-crypto only** |

### Critical Discovery: Conversion Limitation

`/getConversion` **only works for crypto-to-crypto** on free tier:
- ✅ BTC → ETH (works)
- ✅ ETH → USDT (works)
- ❌ BTC → USD (requires PRO)

**Workaround**: Use USDT or USDC as USD-pegged stablecoins for USD-like valuations.

## Verified PRO Tier Endpoints (15 Total)

All these returned "upgrade subscription" errors with free API key:

| Endpoint | Error Message | Category |
|----------|---------------|----------|
| `/getTop` | "No access. Please upgrade your subscription" | Market |
| `/getDataCurrency` | "No access. Please upgrade your subscription" | Market |
| `/getFearGreed` | "No access. Please upgrade your subscription" | Sentiment |
| `/getHistory` | "No access. Please upgrade your subscription" | Historical |
| `/getOHLC` | "Your plan does not include historical data" | Historical |
| `/getTimeframe` | "No access. Please upgrade your subscription" | Historical |
| `/getPerformance` | "No access. Please upgrade your subscription" | Technical |
| `/getTechnicalAnalysis` | "No access. Please upgrade your subscription" | Technical |
| `/getVolatility` | "No access. Please upgrade your subscription" | Technical |
| `/getBreakouts` | "No access. Please upgrade your subscription" | Technical |
| `/getSupportResistance` | "No access. Please upgrade your subscription" | Technical |
| `/getMARibbon` | "No access. Please upgrade your subscription" | Technical |
| `/getBollinger` | "No access. Please upgrade your subscription" | Technical |
| `/getATHATL` | "No access. Please upgrade your subscription" | Market |
| `/getNews` | "No access. Please upgrade your subscription" | News |

## Implementation Rules

### Default to Free Tier

**ALWAYS implement free tier endpoints first** unless user explicitly states they have PRO access.

```
✅ GOOD: "I'll implement live price tracking using /getData (free tier)"
❌ BAD:  "I'll use /getTop to show rankings" (requires PRO)
```

### When User Requests PRO Features

If user asks for features not available on free tier:

1. **Acknowledge the request**: "You asked for Fear & Greed index data..."
2. **Explain the limitation**: "...which requires a PRO subscription ($19.99/month)"
3. **Offer alternatives**: "I can implement live price tracking instead using the free tier"
4. **Get confirmation**: "Would you like me to proceed with free tier, or do you have PRO access?"

### Common PRO-Only Features to Watch For

- ❌ Top cryptocurrency rankings (`/getTop`)
- ❌ Fear & Greed index (`/getFearGreed`)
- ❌ Local currency pricing (`/getDataCurrency`)
- ❌ Historical data (any `/getHistory`, `/getOHLC`, `/getTimeframe`)
- ❌ Technical analysis (`/getTechnicalAnalysis`, `/getBollinger`, etc.)
- ❌ Crypto-to-fiat conversion (`/getConversion` with USD/EUR)
- ❌ Performance metrics (`/getPerformance`)
- ❌ Volatility data (`/getVolatility`)
- ❌ Crypto news (`/getNews`)

## Testing Checklist

When implementing FreeCryptoAPI:

- [ ] Verify user wants free or PRO features
- [ ] Use `/getData` for price data (free)
- [ ] Use `/getConversion` only for crypto-to-crypto (free)
- [ ] Use USDT/USDC instead of USD (free workaround)
- [ ] Mention PRO requirement before implementing paid features
- [ ] Confirm user has PRO access if they request paid features

## Rate Limits

| Tier | Monthly | Daily | Hourly | Minute |
|------|---------|-------|--------|--------|
| FREE | 100,000 | ~3,333 | ~139 | ~2.3 |
| PRO | 10,000,000 | ~333,333 | ~13,888 | ~231 |

**Recommendation**: Cache responses for 30-60 seconds minimum. Prices don't change every second.

## Error Codes

| Code | Meaning | Action |
|------|---------|--------|
| 200 | Success | Process response |
| 400 | Bad Request | Check parameters |
| 401 | Unauthorized | Invalid API key |
| 403 | Forbidden | PRO endpoint on free tier |
| 404 | Not Found | Invalid symbol |
| 429 | Rate Limited | Backoff and retry |
| 500 | Server Error | Retry with backoff |

See [errors-and-edge-cases.md](errors-and-edge-cases.md) for detailed error handling.

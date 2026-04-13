---
name: freecryptoapi
description: Helps developers use the FreeCryptoAPI for cryptocurrency prices, market data, and crypto-to-crypto conversion. FREE TIER focused - covers verified free endpoints including live prices, exchange data, and crypto conversion. PRO tier endpoints like historical data, technical analysis, top rankings, and crypto-to-fiat conversion are marked [PRO]. Use when implementing Bitcoin price tracking, ETH data, cryptocurrency APIs, or any crypto data needs.
---

# FreeCryptoAPI Usage Guide

## What This Skill Does

Provides guidance for using FreeCryptoAPI's free tier (100,000 requests/month). Focuses on verified free endpoints for live cryptocurrency data and crypto-to-crypto conversion. PRO features are clearly marked and require $19.99/month subscription.

**Verified FREE Endpoints**: `/getData`, `/getCryptoList`, `/getExchange`, `/getConversion` (crypto-to-crypto only)

**API Base URL**: `https://api.freecryptoapi.com/v1`

## API Tier Reference

See [references/free-vs-pro.md](references/free-vs-pro.md) for complete tier documentation including:
- All 4 verified FREE endpoints with test results
- All 15 PRO endpoints requiring subscription
- Implementation rules and error codes
- Rate limits (100K/month FREE, 10M/month PRO)

### Quick Tier Summary

| Feature | FREE | PRO |
|---------|------|-----|
| **Requests/Month** | 100,000 | 10,000,000 |
| **Live Prices** (`/getData`) | ✅ | ✅ |
| **Crypto List** (`/getCryptoList`) | ✅ | ✅ |
| **Exchange Data** (`/getExchange`) | ✅ | ✅ |
| **Conversion** (`/getConversion`) | Crypto-to-crypto only | Crypto-to-fiat + crypto |
| **Top Rankings** (`/getTop`) | ❌ | ✅ |
| **Local Currency** (`/getDataCurrency`) | ❌ | ✅ |
| **Fear & Greed** (`/getFearGreed`) | ❌ | ✅ |
| **Historical Data** | ❌ | ✅ |
| **Technical Analysis** | ❌ | ✅ |

**Critical Discovery**: `/getConversion` **only works for crypto-to-crypto on free tier** (BTC→ETH, ETH→USDT). Crypto-to-fiat (BTC→USD) requires PRO. Use USDT as USD-pegged alternative.

## When to Use This Skill

Use this skill when the user:
- Mentions "FreeCryptoAPI", "crypto API", or "cryptocurrency prices"
- Needs Bitcoin (BTC), Ethereum (ETH), or altcoin price data
- Wants crypto-to-crypto conversion (BTC→ETH, ETH→USDT)
- Requests real-time cryptocurrency tracking or portfolio valuation
- Needs exchange-specific cryptocurrency data
- Is building a crypto dashboard, trading bot, or price alert system

**Important**: When user requests PRO-only features (top rankings, Fear & Greed, historical data, technical analysis, crypto-to-fiat), inform them these require PRO subscription. Only implement if they explicitly confirm PRO access.

## Authentication

### Getting an API Key

1. Visit `https://freecryptoapi.com/`
2. Click "Get Free API Key"
3. Register and copy your key from the dashboard

### Setup Pattern

**Python**:
```python
import os
import requests

API_KEY = os.getenv("FREECRYPTO_API_KEY")
API_BASE = "https://api.freecryptoapi.com/v1"

headers = {
    "Authorization": f"Bearer {API_KEY}",
    "Content-Type": "application/json"
}
```

**TypeScript**:
```typescript
const API_KEY = process.env.FREECRYPTO_API_KEY;
const API_BASE = "https://api.freecryptoapi.com/v1";

const headers = {
    "Authorization": `Bearer ${API_KEY}`,
    "Content-Type": "application/json"
};
```

**Ruby**:
```ruby
API_KEY = ENV['FREECRYPTO_API_KEY']
API_BASE = 'https://api.freecryptoapi.com/v1'

headers = {
    'Authorization' => "Bearer #{API_KEY}",
    'Content-Type' => 'application/json'
}
```

**Security**: Never hardcode API keys. Use environment variables. For web apps, use backend proxy - never expose keys client-side.

## FREE Tier Implementation Patterns

### Pattern 1: Get Live Price Data

**Endpoint**: `GET /getData?symbol={symbol}`

**Python**:
```python
def get_crypto_data(symbol: str):
    response = requests.get(
        f"{API_BASE}/getData",
        params={"symbol": symbol},
        headers=headers,
        timeout=30
    )
    
    if response.status_code == 404:
        return None  # Symbol not found
    
    response.raise_for_status()
    return response.json()

# Usage
btc = get_crypto_data("BTC")
print(f"BTC: ${btc['price']:,}")
```

**TypeScript**:
```typescript
async function getCryptoData(symbol: string) {
    const response = await fetch(
        `${API_BASE}/getData?symbol=${encodeURIComponent(symbol)}`,
        { headers }
    );
    
    if (response.status === 404) return null;
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    
    return await response.json();
}
```

**Ruby**:
```ruby
def get_crypto_data(symbol)
    uri = URI("#{API_BASE}/getData")
    uri.query = URI.encode_www_form('symbol' => symbol)
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    request = Net::HTTP::Get.new(uri)
    headers.each { |k, v| request[k] = v }
    
    response = http.request(request)
    return nil if response.code == '404'
    
    JSON.parse(response.body)
end
```

**Multiple Symbols**: Use `+` separator for batch requests (more efficient):
```python
# Get BTC, ETH, SOL in one request
response = requests.get(
    f"{API_BASE}/getData",
    params={"symbol": "BTC+ETH+SOL"},
    headers=headers
)
```

### Pattern 2: Crypto-to-Crypto Conversion

**Endpoint**: `GET /getConversion?from={from}&to={to}&amount={amount}`

**FREE Tier Limitation**: Crypto-to-crypto only (BTC→ETH, ETH→USDT). Crypto-to-fiat requires PRO.

**Python**:
```python
def convert_crypto(from_symbol: str, to_symbol: str, amount: float):
    """Convert crypto-to-crypto (FREE tier)."""
    response = requests.get(
        f"{API_BASE}/getConversion",
        params={
            "from": from_symbol,
            "to": to_symbol,
            "amount": amount
        },
        headers=headers,
        timeout=30
    )
    
    if response.status_code == 404:
        return None  # Conversion not available
    
    response.raise_for_status()
    return response.json()['converted_amount']

# FREE tier examples (crypto-to-crypto)
eth_amount = convert_crypto("BTC", "ETH", 1.0)  # ✅ Works
usdt_amount = convert_crypto("ETH", "USDT", 1.0)  # ✅ Works (USDT = USD-pegged)

# This requires PRO:
# usd_amount = convert_crypto("BTC", "USD", 1.0)  # ❌ Requires PRO
```

**Workaround for USD values**: Use USDT (Tether) or USDC as USD-pegged stablecoins for crypto-to-fiat-like conversions on free tier.

### Pattern 3: Portfolio Valuation

```python
def get_portfolio_value(holdings: dict) -> float:
    """
    Calculate portfolio value from holdings dict.
    holdings = {"BTC": 0.5, "ETH": 2.0, "SOL": 10.0}
    """
    if not holdings:
        return 0.0
    
    symbols = list(holdings.keys())
    symbol_string = "+".join(symbols)
    
    response = requests.get(
        f"{API_BASE}/getData",
        params={"symbol": symbol_string},
        headers=headers,
        timeout=30
    )
    response.raise_for_status()
    
    data = response.json()
    prices = {item['symbol']: item['price'] for item in data}
    
    return sum(
        holdings[symbol] * prices.get(symbol, 0)
        for symbol in holdings
    )

# Usage
portfolio = {"BTC": 0.5, "ETH": 2.0, "SOL": 10.0}
total = get_portfolio_value(portfolio)
print(f"Portfolio Value: ${total:,.2f}")
```

### Pattern 4: Exchange-Specific Data

```python
def get_exchange_data(exchange: str):
    """Get all pairs on a specific exchange (e.g., 'binance')."""
    response = requests.get(
        f"{API_BASE}/getExchange",
        params={"exchange": exchange},
        headers=headers,
        timeout=30
    )
    response.raise_for_status()
    return response.json()

# Usage
binance_data = get_exchange_data("binance")
print(f"Pairs on Binance: {len(binance_data['symbols'])}")
```

## Best Practices

### Rate Limiting (100K/month on FREE)

```python
# Cache for 60 seconds minimum - prices don't change every second
CACHE_DURATION = 60

def get_cached_price(symbol: str):
    cache_key = f"price_{symbol}"
    
    # Check cache
    if cache_key in cache:
        timestamp, data = cache[cache_key]
        if time.time() - timestamp < CACHE_DURATION:
            return data
    
    # Fetch fresh
    data = get_crypto_data(symbol)
    cache[cache_key] = (time.time(), data)
    return data
```

**Rate limit math**: 100,000/month ≈ 3,333/day ≈ 139/hour ≈ 2.3/minute average.

### Error Handling

```python
def safe_api_call(url: str, params: dict = None, max_retries: int = 3):
    """Call API with error handling and retries."""
    for attempt in range(max_retries):
        try:
            response = requests.get(
                url,
                params=params,
                headers=headers,
                timeout=30
            )
            
            # Handle specific errors
            if response.status_code == 401:
                raise Exception("Invalid API key")
            
            if response.status_code == 403:
                raise Exception("PRO feature requires subscription")
            
            if response.status_code == 404:
                return None  # Symbol not found
            
            if response.status_code == 429:
                # Rate limited - wait and retry
                if attempt < max_retries - 1:
                    time.sleep(60)
                    continue
                raise Exception("Rate limit exceeded")
            
            if response.status_code >= 500:
                if attempt < max_retries - 1:
                    time.sleep(5)
                    continue
                raise Exception("Server error")
            
            response.raise_for_status()
            return response.json()
            
        except requests.exceptions.Timeout:
            if attempt < max_retries - 1:
                time.sleep(5)
                continue
            raise Exception("Request timeout")
        
        except requests.exceptions.ConnectionError:
            if attempt < max_retries - 1:
                time.sleep(5)
                continue
            raise Exception("Network error")
```

See [references/errors-and-edge-cases.md](references/errors-and-edge-cases.md) for complete error handling guide.

## Implementation Rules

### Rule 1: Default to Free Tier

**ALWAYS** start with free tier implementation unless user explicitly confirms PRO access.

```
✅ GOOD: "I'll implement live price tracking using /getData (free tier)"
❌ BAD: "I'll use /getTop to show rankings" (requires PRO)
```

### Rule 2: Inform About PRO Requirements

When user requests PRO features:

1. **Acknowledge**: "You asked for top cryptocurrency rankings..."
2. **Explain**: "...which requires a PRO subscription ($19.99/month)"
3. **Offer alternative**: "I can implement live price tracking instead using the free tier"
4. **Get confirmation**: "Would you like to proceed with free tier, or do you have PRO access?"

### Rule 3: Use Workarounds

When PRO features are requested but user doesn't have PRO:

| PRO Feature Requested | FREE Tier Workaround |
|---------------------|---------------------|
| Top rankings | Track popular symbols manually |
| Local currency (USD, EUR) | Use USDT as USD-pegged alternative |
| Fear & Greed index | Skip or use external sources |
| Historical data | Track and store prices yourself |
| Crypto-to-fiat conversion | Convert to USDT instead |

## Code Examples by Language

See reference files for complete implementations:

- **[references/python.md](references/python.md)** - Python examples with caching, error handling, and complete working examples
- **[references/typescript.md](references/typescript.md)** - TypeScript/JavaScript examples with async/await and type definitions
- **[references/ruby.md](references/ruby.md)** - Ruby examples with Net::HTTP and complete class implementation

## PRO Tier Reference

See [references/pro-endpoints.md](references/pro-endpoints.md) for complete PRO tier documentation including:
- All 15+ PRO endpoints with parameters and examples
- When to upgrade to PRO
- Free tier workarounds for PRO features
- Historical data, technical analysis, sentiment analysis endpoints

## SDK References

Official SDKs available at `https://freecryptoapi.com/sdk`:
- Python: `pip install freecryptoapi`
- JavaScript/TypeScript: `npm install freecryptoapi`
- PHP: Drop-in file
- Java: Drop-in file
- C#/.NET: Drop-in file

This guide focuses on direct REST API usage for maximum flexibility. Use SDKs for rapid development, or direct API calls for fine-grained control.

## Complete Working Example

```python
import os
import time
import requests
from typing import Dict, Optional

class FreeCryptoTracker:
    """Simple crypto tracker using FREE tier endpoints only."""
    
    def __init__(self):
        self.api_key = os.getenv("FREECRYPTO_API_KEY")
        self.base_url = "https://api.freecryptoapi.com/v1"
        self.headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }
        self.cache = {}
        self.cache_duration = 60
    
    def get_price(self, symbol: str) -> Optional[Dict]:
        """Get current price (with caching)."""
        cache_key = f"price_{symbol}"
        
        # Check cache
        if cache_key in self.cache:
            timestamp, data = self.cache[cache_key]
            if time.time() - timestamp < self.cache_duration:
                return data
        
        # Fetch fresh
        try:
            response = requests.get(
                f"{self.base_url}/getData",
                params={"symbol": symbol},
                headers=self.headers,
                timeout=30
            )
            
            if response.status_code == 404:
                return None
            
            response.raise_for_status()
            data = response.json()
            self.cache[cache_key] = (time.time(), data)
            return data
        except Exception as e:
            print(f"Error: {e}")
            return None
    
    def get_portfolio_value(self, holdings: Dict[str, float]) -> Optional[float]:
        """Calculate total portfolio value."""
        symbols = list(holdings.keys())
        if not symbols:
            return 0.0
        
        try:
            symbol_string = "+".join(symbols)
            response = requests.get(
                f"{self.base_url}/getData",
                params={"symbol": symbol_string},
                headers=self.headers,
                timeout=30
            )
            response.raise_for_status()
            
            data = response.json()
            prices = {item['symbol']: item['price'] for item in data}
            
            return sum(
                holdings[s] * prices.get(s, 0) for s in holdings
            )
        except Exception as e:
            print(f"Error: {e}")
            return None
    
    def convert(self, from_sym: str, to_sym: str, amount: float) -> Optional[float]:
        """Convert crypto-to-crypto (FREE tier)."""
        try:
            response = requests.get(
                f"{self.base_url}/getConversion",
                params={"from": from_sym, "to": to_sym, "amount": amount},
                headers=self.headers,
                timeout=30
            )
            
            if response.status_code == 404:
                return None
            
            response.raise_for_status()
            return response.json()['converted_amount']
        except Exception as e:
            print(f"Error: {e}")
            return None

# Usage
if __name__ == "__main__":
    tracker = FreeCryptoTracker()
    
    portfolio = {"BTC": 0.5, "ETH": 2.0, "SOL": 10.0}
    
    print("Portfolio Tracker (Free Tier)")
    print("=" * 40)
    
    # Show prices
    for symbol in portfolio:
        data = tracker.get_price(symbol)
        if data:
            value = portfolio[symbol] * data['price']
            print(f"{symbol}: {portfolio[symbol]} × ${data['price']:,.2f} = ${value:,.2f}")
    
    # Total value
    total = tracker.get_portfolio_value(portfolio)
    if total:
        print(f"\nTotal Value: ${total:,.2f}")
    
    # Crypto conversion (BTC → ETH)
    result = tracker.convert("BTC", "ETH", 1.0)
    if result:
        print(f"\n1 BTC = {result:.6f} ETH")
```

## Reference Index

| Reference File | Contents |
|---------------|----------|
| [references/free-vs-pro.md](references/free-vs-pro.md) | Complete tier documentation, verified endpoints, rate limits |
| [references/python.md](references/python.md) | Python implementation examples |
| [references/typescript.md](references/typescript.md) | TypeScript/JavaScript examples |
| [references/ruby.md](references/ruby.md) | Ruby implementation examples |
| [references/pro-endpoints.md](references/pro-endpoints.md) | PRO tier endpoints documentation |
| [references/errors-and-edge-cases.md](references/errors-and-edge-cases.md) | Error handling and edge cases |

## Quick Reference Card

**FREE Tier Endpoints** (always available):
```
GET /getData?symbol=BTC              # Live price
GET /getData?symbol=BTC+ETH+SOL      # Multiple prices
GET /getCryptoList                    # All supported coins
GET /getExchange?exchange=binance    # Exchange data
GET /getConversion?from=BTC&to=ETH&amount=1  # Crypto-to-crypto only
```

**PRO Tier Endpoints** (subscription required):
```
GET /getTop?top=10                    # Rankings
GET /getDataCurrency?symbol=BTC&local=USD   # Local currency
GET /getFearGreed                     # Sentiment
GET /getOHLC?symbol=BTC&days=30       # Historical
GET /getTechnicalAnalysis?symbol=BTC  # RSI, MACD
# ... and 10+ more
```

**Error Codes**:
- `200` - Success
- `401` - Invalid API key
- `403` - PRO endpoint on free tier
- `404` - Symbol not found
- `429` - Rate limit exceeded
- `500` - Server error

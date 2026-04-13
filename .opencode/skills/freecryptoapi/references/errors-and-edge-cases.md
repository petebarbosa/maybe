# Error Handling & Edge Cases Reference

Complete guide to handling errors and edge cases when using FreeCryptoAPI.

## HTTP Status Codes

| Code | Meaning | When It Occurs | Action |
|------|---------|----------------|--------|
| 200 | Success | Request successful | Process response |
| 400 | Bad Request | Invalid parameters | Check request format |
| 401 | Unauthorized | Invalid API key | Verify `FREECRYPTO_API_KEY` |
| 403 | Forbidden | PRO endpoint on free tier | Check subscription or use free alternative |
| 404 | Not Found | Invalid symbol | Validate symbol exists |
| 429 | Rate Limited | Too many requests | Implement backoff |
| 500 | Server Error | API server issue | Retry with exponential backoff |

## Error Response Format

All errors return JSON with this structure:

```json
{
  "status": false,
  "error": "Error description",
  "message": "Detailed error message"
}
```

## Common Error Scenarios

### Invalid API Key (401)

```json
{
  "status": false,
  "error": "Invalid API key",
  "message": "The provided API key is not valid"
}
```

**Solution**: Check that `FREECRYPTO_API_KEY` environment variable is set correctly. Get a new key from dashboard if needed.

### PRO Endpoint on Free Tier (403)

```json
{
  "status": false,
  "error": "No access. Please upgrade your subscription"
}
```

Or for historical data:
```json
{
  "status": false,
  "error": "Your plan does not include historical data. Please upgrade."
}
```

**Solution**: Either upgrade to PRO subscription or use free tier alternatives:
- Use `/getData` instead of `/getTop`
- Use USDT for USD-pegged values instead of `/getDataCurrency`
- Skip historical/technical analysis features

### Invalid Symbol (404)

```json
{
  "status": false,
  "error": "Symbol not found",
  "message": "Could not find cryptocurrency XYZ"
}
```

**Solution**: Validate symbols against `/getCryptoList` before API calls.

### Rate Limit Exceeded (429)

```json
{
  "status": false,
  "error": "Rate limit exceeded",
  "message": "You have exceeded your monthly request limit"
}
```

**Solution**: Implement caching and request counting. Cache for 30-60 seconds minimum.

## Error Handling Patterns

### Python

```python
def safe_api_call(url, params=None, max_retries=3):
    """Make API call with comprehensive error handling."""
    for attempt in range(max_retries):
        try:
            response = requests.get(
                url,
                params=params,
                headers=headers,
                timeout=30
            )
            
            # Handle specific status codes
            if response.status_code == 401:
                raise Exception("Invalid API key - check FREECRYPTO_API_KEY")
            
            if response.status_code == 403:
                # PRO endpoint on free tier
                raise Exception("This feature requires PRO subscription")
            
            if response.status_code == 404:
                return None  # Symbol not found
            
            if response.status_code == 429:
                # Rate limited - exponential backoff
                if attempt < max_retries - 1:
                    sleep_time = (2 ** attempt) * 60  # 60s, 120s, 240s
                    print(f"Rate limited. Waiting {sleep_time}s...")
                    time.sleep(sleep_time)
                    continue
                raise Exception("Rate limit exceeded - max retries reached")
            
            if response.status_code >= 500:
                # Server error - retry with backoff
                if attempt < max_retries - 1:
                    sleep_time = 5 * (attempt + 1)
                    print(f"Server error. Retrying in {sleep_time}s...")
                    time.sleep(sleep_time)
                    continue
                raise Exception("Server error - max retries reached")
            
            response.raise_for_status()
            return response.json()
            
        except requests.exceptions.Timeout:
            if attempt < max_retries - 1:
                print("Timeout. Retrying...")
                time.sleep(5)
                continue
            raise Exception("Request timeout - API may be slow")
            
        except requests.exceptions.ConnectionError:
            if attempt < max_retries - 1:
                print("Connection error. Retrying...")
                time.sleep(5)
                continue
            raise Exception("Network error - check internet connection")
    
    raise Exception("Max retries exceeded")
```

### TypeScript/JavaScript

```typescript
async function safeApiCall(
    url: string,
    maxRetries = 3
): Promise<any> {
    for (let attempt = 0; attempt < maxRetries; attempt++) {
        try {
            const response = await fetch(url, { headers, timeout: 30000 });
            
            if (response.status === 401) {
                throw new Error("Invalid API key - check FREECRYPTO_API_KEY");
            }
            
            if (response.status === 403) {
                throw new Error("This feature requires PRO subscription");
            }
            
            if (response.status === 404) {
                return null; // Symbol not found
            }
            
            if (response.status === 429) {
                if (attempt < maxRetries - 1) {
                    const sleepTime = Math.pow(2, attempt) * 60000;
                    console.log(`Rate limited. Waiting ${sleepTime/1000}s...`);
                    await new Promise(r => setTimeout(r, sleepTime));
                    continue;
                }
                throw new Error("Rate limit exceeded - max retries");
            }
            
            if (response.status >= 500) {
                if (attempt < maxRetries - 1) {
                    await new Promise(r => setTimeout(r, 5000 * (attempt + 1)));
                    continue;
                }
                throw new Error("Server error - max retries");
            }
            
            if (!response.ok) {
                throw new Error(`HTTP ${response.status}`);
            }
            
            return await response.json();
            
        } catch (error) {
            if (attempt === maxRetries - 1) throw error;
            console.log(`Error on attempt ${attempt + 1}, retrying...`);
            await new Promise(r => setTimeout(r, 5000));
        }
    }
}
```

## Edge Cases

### Symbol Format Variations

Different formats users might use: `BTC`, `btc`, `BTCUSD`, `BTC-USD`, `bitcoin`

**Handling**:
```python
def normalize_symbol(symbol: str) -> str:
    """Normalize symbol to uppercase standard format."""
    # Remove common suffixes/prefixes
    symbol = symbol.upper().replace('USD', '').replace('-', '')
    
    # Map common name variations
    symbol_map = {
        'BITCOIN': 'BTC',
        'ETHEREUM': 'ETH',
        'SOLANA': 'SOL'
    }
    
    return symbol_map.get(symbol, symbol)

# Validate against API
valid_symbols = [crypto['symbol'] for crypto in get_crypto_list()]
if symbol not in valid_symbols:
    raise ValueError(f"Invalid symbol: {symbol}")
```

### Floating-Point Precision

Crypto prices can have many decimal places: `0.00001234 BTC = $0.90123456 USD`

**Handling**:
```python
from decimal import Decimal, ROUND_HALF_UP

def precise_calculate(amount: float, price: float) -> Decimal:
    """Use decimal arithmetic for financial calculations."""
    amount_dec = Decimal(str(amount))
    price_dec = Decimal(str(price))
    
    value = amount_dec * price_dec
    return value.quantize(Decimal('0.01'), rounding=ROUND_HALF_UP)

# Format for display only
def format_crypto(value: float, decimals: int = 8) -> str:
    """Format cryptocurrency value with appropriate decimals."""
    return f"{value:.{decimals}f}"

def format_fiat(value: float) -> str:
    """Format fiat currency with 2 decimals."""
    return f"${value:,.2f}"
```

### Cache Stale Data

When API is unavailable, show cached data with warning:

```python
def get_crypto_data_with_fallback(symbol: str) -> Optional[Dict]:
    """Get crypto data with cache fallback."""
    cache_key = f"price_{symbol}"
    
    try:
        # Try fresh API call
        data = get_crypto_data(symbol)
        if data:
            cache.set(cache_key, data, ttl=3600)  # Cache for 1 hour
            return data
    except Exception as e:
        print(f"API error: {e}")
    
    # Fallback to cached data
    cached = cache.get(cache_key)
    if cached:
        print("⚠️  Using cached data (API unavailable)")
        return cached
    
    return None
```

### Concurrent Request Management

Too many concurrent requests can overwhelm the API:

```python
import asyncio
from aiohttp import ClientSession, TCPConnector

async def fetch_many_concurrent(symbols: List[str], max_concurrent: int = 5):
    """Fetch multiple symbols with limited concurrency."""
    connector = TCPConnector(limit=max_concurrent)
    
    async with ClientSession(connector=connector) as session:
        tasks = [
            fetch_symbol(session, symbol)
            for symbol in symbols
        ]
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        return [
            result for result in results
            if not isinstance(result, Exception)
        ]
```

### Graceful Degradation for PRO Features

When user requests PRO feature on free tier:

```python
class FeatureNotAvailableError(Exception):
    """Raised when PRO feature is requested on free tier."""
    pass

def get_historical_data(symbol: str, days: int) -> List[Dict]:
    """
    Get historical data. 
    
    Raises:
        FeatureNotAvailableError: If user doesn't have PRO
    """
    if not has_pro_subscription():
        raise FeatureNotAvailableError(
            "Historical data requires PRO subscription. "
            "Consider using current price data from /getData instead."
        )
    
    # ... implementation for PRO users

# Usage with graceful fallback
try:
    history = get_historical_data("BTC", 30)
except FeatureNotAvailableError as e:
    print(f"⚠️  {e}")
    # Fallback to current price
    current = get_crypto_data("BTC")
    print(f"Current price available: ${current['price']}")
```

See [free-vs-pro.md](free-vs-pro.md) for complete tier information.
See language-specific reference files for implementation examples.

# Python Examples for FreeCryptoAPI

Complete Python implementation examples for FreeCryptoAPI free tier endpoints.

## Setup and Authentication

```python
import requests
import os
from typing import Dict, Optional, List

# Get API key from environment variable
API_KEY = os.getenv("FREECRYPTO_API_KEY")
API_BASE = "https://api.freecryptoapi.com/v1"

if not API_KEY:
    raise ValueError("FREECRYPTO_API_KEY environment variable not set")

headers = {
    "Authorization": f"Bearer {API_KEY}",
    "Content-Type": "application/json"
}
```

## FREE Tier Examples

### Get Live Cryptocurrency Data

```python
def get_crypto_data(symbol: str) -> Optional[Dict]:
    """Fetch live market data for a cryptocurrency."""
    try:
        response = requests.get(
            f"{API_BASE}/getData",
            params={"symbol": symbol},
            headers=headers,
            timeout=30
        )
        
        if response.status_code == 404:
            return None
        
        if response.status_code == 429:
            raise Exception("Rate limit exceeded")
        
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f"Error: {e}")
        return None

# Usage
btc_data = get_crypto_data("BTC")
if btc_data:
    print(f"BTC Price: ${btc_data['price']:,}")
    print(f"24h Change: {btc_data['change_percentage_24h']}%")
```

### Get Multiple Cryptocurrencies

```python
def get_multiple_cryptos(symbols: List[str]) -> Dict[str, Dict]:
    """Fetch data for multiple cryptocurrencies in one request."""
    symbol_string = "+".join(symbols)
    
    try:
        response = requests.get(
            f"{API_BASE}/getData",
            params={"symbol": symbol_string},
            headers=headers,
            timeout=30
        )
        response.raise_for_status()
        data = response.json()
        
        # API returns single object for one symbol, list for multiple
        if isinstance(data, list):
            return {item['symbol']: item for item in data}
        else:
            return {data['symbol']: data}
    except requests.exceptions.RequestException as e:
        print(f"Error: {e}")
        return {}

# Usage
portfolio = get_multiple_cryptos(["BTC", "ETH", "SOL", "ADA"])
for symbol, data in portfolio.items():
    print(f"{symbol}: ${data['price']:.2f}")
```

### List All Supported Cryptocurrencies

```python
def get_crypto_list() -> List[Dict]:
    """Get list of all supported cryptocurrencies."""
    try:
        response = requests.get(
            f"{API_BASE}/getCryptoList",
            headers=headers,
            timeout=30
        )
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f"Error: {e}")
        return []

# Usage
crypto_list = get_crypto_list()
print(f"Total supported: {len(crypto_list)}")
```

### Cryptocurrency Conversion (Crypto-to-Crypto Only)

**Important**: FREE tier only supports crypto-to-crypto conversions. Crypto-to-fiat (BTC→USD) requires PRO.

```python
def convert_crypto(from_symbol: str, to_symbol: str, amount: float) -> Optional[float]:
    """
    Convert amount from one cryptocurrency to another.
    
    FREE tier: crypto-to-crypto only (BTC→ETH, ETH→USDT)
    PRO tier: includes crypto-to-fiat (BTC→USD)
    """
    try:
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
            print(f"Conversion not available")
            return None
        
        response.raise_for_status()
        result = response.json()
        return result['converted_amount']
    except requests.exceptions.RequestException as e:
        print(f"Error: {e}")
        return None

# Usage - FREE tier examples (crypto-to-crypto)
eth_amount = convert_crypto("BTC", "ETH", 1.0)
if eth_amount:
    print(f"1 BTC = {eth_amount:.6f} ETH")

# Use USDT as USD-pegged alternative
usdt_amount = convert_crypto("ETH", "USDT", 1.0)
if usdt_amount:
    print(f"1 ETH = {usdt_amount:.2f} USDT")
```

### Get Exchange-Specific Data

```python
def get_exchange_data(exchange: str) -> Optional[Dict]:
    """Get all trading pairs and data for a specific exchange."""
    try:
        response = requests.get(
            f"{API_BASE}/getExchange",
            params={"exchange": exchange},
            headers=headers,
            timeout=30
        )
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f"Error: {e}")
        return None

# Usage
binance_data = get_exchange_data("binance")
if binance_data:
    print(f"Available pairs: {len(binance_data['pairs'])}")
```

## Complete Working Example

```python
import os
import time
import requests
from typing import Dict, Optional

class FreeCryptoTracker:
    """Simple cryptocurrency tracker using FreeCryptoAPI free tier."""
    
    def __init__(self):
        self.api_key = os.getenv("FREECRYPTO_API_KEY")
        self.base_url = "https://api.freecryptoapi.com/v1"
        self.headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }
        self.cache = {}
        self.cache_duration = 60  # seconds
    
    def _get_cached(self, key: str) -> Optional[Dict]:
        if key in self.cache:
            timestamp, data = self.cache[key]
            if time.time() - timestamp < self.cache_duration:
                return data
        return None
    
    def _set_cached(self, key: str, data: Dict):
        self.cache[key] = (time.time(), data)
    
    def get_price(self, symbol: str) -> Optional[Dict]:
        """Get current price data (with caching)."""
        cache_key = f"price_{symbol}"
        cached = self._get_cached(cache_key)
        if cached:
            return cached
        
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
            self._set_cached(cache_key, data)
            return data
        except Exception as e:
            print(f"Error: {e}")
            return None
    
    def get_portfolio_value(self, holdings: Dict[str, float]) -> Optional[float]:
        """Calculate total portfolio value from holdings."""
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
            
            total = sum(holdings[symbol] * prices.get(symbol, 0) for symbol in holdings)
            return total
        except Exception as e:
            print(f"Error: {e}")
            return None
    
    def convert(self, from_symbol: str, to_symbol: str, amount: float) -> Optional[float]:
        """Convert between cryptocurrencies (crypto-to-crypto only on free tier)."""
        try:
            response = requests.get(
                f"{self.base_url}/getConversion",
                params={
                    "from": from_symbol,
                    "to": to_symbol,
                    "amount": amount
                },
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
    
    portfolio = {
        "BTC": 0.5,
        "ETH": 2.0,
        "SOL": 10.0
    }
    
    print("Portfolio Tracker (Free Tier)")
    print("=" * 40)
    
    # Show individual prices
    for symbol in portfolio:
        data = tracker.get_price(symbol)
        if data:
            value = portfolio[symbol] * data['price']
            print(f"{symbol}: {portfolio[symbol]} × ${data['price']:,.2f} = ${value:,.2f}")
    
    # Show total value
    total = tracker.get_portfolio_value(portfolio)
    if total:
        print(f"\nTotal Portfolio Value: ${total:,.2f}")
    
    # Show crypto-to-crypto conversion
    btc_to_eth = tracker.convert("BTC", "ETH", 1.0)
    if btc_to_eth:
        print(f"\n1 BTC = {btc_to_eth:.6f} ETH")
```

## PRO Tier Examples (Reference Only)

These examples are for reference only and require PRO subscription:

### Get Top Cryptocurrencies **[PRO]**

```python
def get_top_cryptos(top_n: int = 10) -> List[Dict]:
    """Get top N cryptocurrencies by market cap. [PRO ONLY]"""
    try:
        response = requests.get(
            f"{API_BASE}/getTop",
            params={"top": min(top_n, 200)},
            headers=headers,
            timeout=30
        )
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f"Error: {e}")
        return []

# Requires PRO subscription
top_10 = get_top_cryptos(10)
for i, crypto in enumerate(top_10, 1):
    print(f"{i}. {crypto['symbol']}: ${crypto['price']:.2f}")
```

### Fear & Greed Index **[PRO]**

```python
def get_fear_greed_index() -> Optional[Dict]:
    """Get the Fear & Greed Index. [PRO ONLY]"""
    try:
        response = requests.get(
            f"{API_BASE}/getFearGreed",
            headers=headers,
            timeout=30
        )
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f"Error: {e}")
        return None

# Requires PRO subscription
sentiment = get_fear_greed_index()
if sentiment:
    print(f"Fear & Greed: {sentiment['value_classification']} ({sentiment['value']}/100)")
```

See [free-vs-pro.md](free-vs-pro.md) for complete tier information.
See [errors-and-edge-cases.md](errors-and-edge-cases.md) for error handling patterns.

# PRO Tier Endpoints Reference

Complete reference for FreeCryptoAPI PRO tier endpoints. These require a $19.99/month subscription.

## When to Upgrade to PRO

Consider PRO subscription when you need:
- Historical price data (OHLC, time series)
- Technical analysis (RSI, MACD, Bollinger Bands)
- Market sentiment (Fear & Greed Index)
- Top cryptocurrency rankings
- Local currency pricing (USD, EUR, GBP, TRY)
- Crypto-to-fiat conversions
- Higher rate limits (10M vs 100K requests/month)

## PRO Tier Endpoints

### Market Data

#### Get Top Cryptocurrencies
```
GET /getTop?top={n}
```

Returns top N cryptocurrencies by market cap.

**Parameters**:
- `top` (int): Number of cryptocurrencies to return (max 200)

**Example**:
```python
response = requests.get(
    f"{API_BASE}/getTop",
    params={"top": 10},
    headers=headers
)
top_10 = response.json()
```

**Use Case**: Build cryptocurrency rankings, display market leaders

---

#### Get Data in Local Currency
```
GET /getDataCurrency?symbol={symbol}&local={currency}
```

Returns cryptocurrency data priced in a specific fiat currency.

**Parameters**:
- `symbol` (string): Cryptocurrency symbol (e.g., 'BTC')
- `local` (string): Fiat currency code (e.g., 'USD', 'EUR', 'GBP', 'TRY')

**Example**:
```python
response = requests.get(
    f"{API_BASE}/getDataCurrency",
    params={"symbol": "BTC", "local": "EUR"},
    headers=headers
)
btc_eur = response.json()
print(f"BTC: €{btc_eur['price']}")
```

**Use Case**: Display prices in user's local currency

---

### Sentiment Analysis

#### Fear & Greed Index
```
GET /getFearGreed
```

Returns cryptocurrency market Fear & Greed Index.

**Response**:
```json
{
  "value": 75,
  "value_classification": "Greed",
  "trend": "increasing"
}
```

**Interpretation**:
- 0-24: Extreme Fear
- 25-49: Fear
- 50-74: Greed
- 75-100: Extreme Greed

**Use Case**: Market sentiment analysis, contrarian indicators

---

### Historical Data

#### Get OHLC (Candlestick) Data
```
GET /getOHLC?symbol={symbol}&days={days}
```

Returns daily OHLC (Open/High/Low/Close) candlestick data.

**Parameters**:
- `symbol` (string): Cryptocurrency symbol
- `days` (int): Number of days of history

**Response**:
```json
[
  {
    "date": "2024-01-01",
    "open": 42000.00,
    "high": 43500.00,
    "low": 41800.00,
    "close": 42800.00,
    "volume": 15000000000
  }
]
```

**Use Case**: Candlestick charts, price history visualization

---

#### Get Historical Data (Timeframe)
```
GET /getTimeframe?symbol={symbol}&start={start}&end={end}
```

Returns historical data for a specific date range.

**Parameters**:
- `symbol` (string): Cryptocurrency symbol
- `start` (string): Start date (YYYY-MM-DD)
- `end` (string): End date (YYYY-MM-DD)

**Use Case**: Historical analysis, backtesting

---

#### Get Last N Days History
```
GET /getHistory?symbol={symbol}&days={days}
```

Returns last N days of historical price data.

**Parameters**:
- `symbol` (string): Cryptocurrency symbol
- `days` (int): Number of days (e.g., 7, 30, 90, 365)

**Use Case**: Recent price history, trend analysis

---

### Performance Metrics

#### Get Performance Data
```
GET /getPerformance?symbol={symbol}
```

Returns performance percentages over multiple timeframes.

**Response**:
```json
{
  "symbol": "BTC",
  "performance": {
    "1d": 2.5,
    "7d": 5.3,
    "30d": 12.8,
    "90d": 45.2,
    "180d": 78.5,
    "365d": 156.3,
    "720d": 234.8
  }
}
```

**Use Case**: Portfolio performance tracking, comparison tools

---

### Technical Analysis

#### Get Technical Analysis Summary
```
GET /getTechnicalAnalysis?symbol={symbol}
```

Returns RSI, MACD, and trading signals.

**Response**:
```json
{
  "symbol": "BTC",
  "rsi": 65.4,
  "macd": {
    "macd_line": 245.3,
    "signal_line": 180.5,
    "histogram": 64.8
  },
  "signal": "BUY"
}
```

**Use Case**: Trading signals, momentum analysis

---

#### Get Bollinger Bands
```
GET /getBollinger?symbol={symbol}&days={days}&period={period}&std_dev={std_dev}
```

Returns Bollinger Bands with squeeze and expansion detection.

**Parameters**:
- `symbol` (string): Cryptocurrency symbol
- `days` (int): Lookback period in days (default: 30)
- `period` (int): Moving average period (default: 20)
- `std_dev` (float): Standard deviation multiplier (default: 2.0)

**Use Case**: Volatility analysis, breakout detection

---

#### Get Moving Average Ribbon
```
GET /getMARibbon?symbol={symbol}&days={days}
```

Returns SMA & EMA ribbon (10/20/50/100/200) with trend signals.

**Use Case**: Trend analysis, multi-timeframe confirmation

---

#### Get Breakout Signals
```
GET /getBreakouts?symbol={symbol}
```

Returns SMA crossover and trend stack detection.

**Response**:
```json
{
  "symbol": "BTC",
  "breakouts": {
    "20_50_sma_cross": "bullish",
    "50_200_sma_cross": "bullish",
    "trend_stack": "strong_uptrend"
  }
}
```

**Use Case**: Trend following, entry/exit signals

---

#### Get Support & Resistance
```
GET /getSupportResistance?symbol={symbol}&period={period}
```

Returns pivot points, Fibonacci, Camarilla & Woodie levels.

**Parameters**:
- `symbol` (string): Cryptocurrency symbol
- `period` (int): Analysis period in days

**Use Case**: Support/resistance trading, price target setting

---

#### Get Volatility Data
```
GET /getVolatility?symbol={symbol}
```

Returns volatility statistics.

**Response**:
```json
{
  "symbol": "BTC",
  "volatility": {
    "30d": 45.2,
    "90d": 52.8,
    "180d": 58.3,
    "360d": 61.5
  }
}
```

**Use Case**: Risk assessment, position sizing

---

#### Get Correlation
```
GET /getCorrelation?symbols={symbols}&days={days}
```

Returns price correlation between multiple assets.

**Parameters**:
- `symbols` (string): Symbols separated by + (e.g., "BTC+ETH+SOL")
- `days` (int): Lookback period in days

**Response**:
```json
{
  "correlations": {
    "BTC_ETH": 0.85,
    "BTC_SOL": 0.72,
    "ETH_SOL": 0.78
  }
}
```

**Use Case**: Portfolio diversification, pair trading

---

### Other Endpoints

#### Get ATH/ATL Data
```
GET /getATHATL?symbol={symbol}&months={months}
```

Returns all-time high/low data and distance from ATH.

**Use Case**: Long-term analysis, entry point evaluation

---

#### Get Crypto News
```
GET /getNews?source={source}&keyword={keyword}
```

Returns latest cryptocurrency news with filtering.

**Parameters**:
- `source` (string, optional): News source filter
- `keyword` (string, optional): Keyword filter

**Use Case**: News sentiment analysis, event-driven trading

---

## PRO Tier Benefits

- **10,000,000 requests/month** (vs 100,000 on free)
- **All historical data endpoints**
- **All technical analysis endpoints**
- **Crypto-to-fiat conversions**
- **Commercial use license**
- **Priority support**

## Implementation Note

When a user requests PRO features:

1. **Inform them of the requirement**: "This feature requires a PRO subscription ($19.99/month)"
2. **Explain the limitation**: Briefly describe what's available on free vs PRO
3. **Offer alternatives**: Suggest free tier workarounds where possible
4. **Get confirmation**: "Would you like to proceed with free tier, or do you have PRO access?"

## Free Tier Workarounds

When PRO features aren't available:

| PRO Feature | Free Alternative |
|-------------|------------------|
| `/getTop` | Manually track popular symbols |
| `/getDataCurrency` | Use USDT as USD-pegged alternative |
| `/getFearGreed` | Skip sentiment analysis |
| `/getHistory` | Store and track prices yourself |
| `/getOHLC` | Build simple price charts from current data |
| `/getConversion` (crypto-to-fiat) | Use crypto-to-crypto with USDT |

See [free-vs-pro.md](free-vs-pro.md) for complete tier comparison.

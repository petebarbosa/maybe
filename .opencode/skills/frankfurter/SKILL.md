---
name: frankfurter
description: Helps developers use the Frankfurter currency exchange API for currency conversion, forex rates, exchange rate lookups, historical rates, time series data, EUR to USD conversion, money exchange, or any application needing real-time or historical currency data from 160+ currencies and 40+ central bank providers. Includes integration patterns, CLI tools, scripts, and web application usage.
---

# Frankfurter Usage Guide

## What This Skill Does

Provides comprehensive guidance for using the Frankfurter currency exchange API. Covers all API endpoints, usage patterns in JavaScript/TypeScript, Python, and Ruby, plus best practices for production use. Suitable for web applications, CLI tools, scripts, data analysis, and any project requiring currency exchange data.

Frankfurter is completely free and open-source with no paid tiers.

Frankfurter is an open-source, free API providing:
- 160+ active currencies from 1977 onward
- 40+ central bank and official data sources
- No API key required
- Real-time and historical exchange rates
- Time series data with grouping
- CSV and NDJSON output formats for large datasets

Base URL: `https://api.frankfurter.dev/v2/`

## When to Use This Skill

Use this skill when the user:
- Mentions "Frankfurter API", "currency API", "forex rates", or "exchange rates"
- Needs currency conversion functionality for any use case (web app, CLI tool, script, data analysis)
- Requests historical exchange rate data or time series
- Asks about EUR to USD or any currency pair conversion
- Wants to build a multi-currency application or dashboard
- Needs money conversion, forex data, or currency exchange functionality
- Wants to fetch exchange rates for spreadsheets, reports, or data processing
- Mentions exchange rate APIs for web/mobile apps, backend services, or automation scripts

## SDKs and Self-Hosting

Frankfurter provides official SDKs and self-hosting options for advanced use cases:

**SDKs Available**: Python, JavaScript/TypeScript, PHP, Java, C#
- Download from: `https://frankfurter.dev/sdk` (if available) or implement using patterns below
- This guide focuses on direct REST API usage for maximum flexibility and understanding

**Self-Hosting**: Deploy your own Frankfurter instance with Docker
- Full control over data and rate limits
- Suitable for high-volume or compliance-sensitive applications
- Documentation: `https://frankfurter.dev/deploy`

For most use cases, the public API at `https://api.frankfurter.dev` is sufficient and requires no setup.

## API Endpoints Reference

### Latest Rates
```
GET /v2/rates
GET /v2/rates?base=USD                    # Change base currency
GET /v2/rates?quotes=USD,GBP,JPY          # Filter target currencies
GET /v2/rates?base=EUR&quotes=USD,GBP   # Combined
```

### Historical Rates
```
GET /v2/rates?date=2025-01-15             # Specific date
GET /v2/rates?from=2025-01-01&to=2025-01-31&quotes=USD  # Time series
GET /v2/rates?from=2025-01-01&group=month               # Monthly grouping
```

### Single Currency Pair
```
GET /v2/rate/EUR/USD                      # Current EUR to USD
GET /v2/rate/EUR/USD?date=2025-01-15    # Historical pair rate
```

### Currency Metadata
```
GET /v2/currencies                        # All currencies with provider coverage
GET /v2/currencies?scope=all              # Include legacy currencies
GET /v2/currency/EUR                      # Single currency details
```

### Data Sources
```
GET /v2/providers                         # List all data providers
GET /v2/rates?providers=ECB               # Filter by provider (ECB, FED, etc.)
```

### Output Formats
```
GET /v2/rates.csv                         # CSV format
GET /v2/rates (Accept: text/csv)          # CSV via header
GET /v2/rates (Accept: application/x-ndjson)  # NDJSON for streaming
```

## Implementation Patterns

### 1. Basic API Client Setup

Always implement with:
- Base URL configuration
- Timeout handling
- Retry logic for transient failures
- User-Agent identification

### 2. Response Parsing Strategy

Frankfurter returns consistent JSON structure:
```json
{
  "base": "EUR",
  "date": "2025-01-15",
  "rates": {
    "USD": 1.0845,
    "GBP": 0.8421,
    "JPY": 162.34
  }
}
```

### 3. Parameter Building

Build query strings dynamically:
- Always URL-encode currency codes
- Use ISO 8601 date format (YYYY-MM-DD)
- Join multiple currencies with commas for `quotes`

### 4. Error Handling

Frankfurter uses standard HTTP status codes:
- `400` - Invalid parameter or malformed request
- `404` - Currency, rate, or resource not found
- `422` - Request understood but cannot be processed

Error response format:
```json
{
  "message": "Could not find currency ABC"
}
```

### 5. Caching Strategy

While no API key is required, implement caching:
- Cache rates for short periods (rates update daily)
- Cache currency metadata longer (changes infrequently)
- Respect rate limits (requests throttled for abuse prevention)

## Code Examples

### JavaScript / TypeScript

#### Basic Rate Fetching
```typescript
const API_BASE = 'https://api.frankfurter.dev/v2';

async function getLatestRates(base: string = 'EUR'): Promise<any> {
  const response = await fetch(`${API_BASE}/rates?base=${base}`);
  
  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.message || `HTTP ${response.status}`);
  }
  
  return response.json();
}

// Usage
const rates = await getLatestRates('USD');
console.log(rates.rates.EUR);  // USD to EUR rate
```

#### Currency Conversion Function
```typescript
async function convertCurrency(
  amount: number,
  from: string,
  to: string
): Promise<number> {
  const response = await fetch(
    `${API_BASE}/rate/${from}/${to}`
  );
  
  if (!response.ok) {
    throw new Error(`Conversion failed: ${response.statusText}`);
  }
  
  const data = await response.json();
  return amount * data.rate;
}

// Usage
const result = await convertCurrency(100, 'EUR', 'USD');
console.log(`100 EUR = ${result.toFixed(2)} USD`);
```

#### Historical Rates Lookup
```typescript
async function getHistoricalRate(
  base: string,
  quote: string,
  date: string  // YYYY-MM-DD format
): Promise<number> {
  const response = await fetch(
    `${API_BASE}/rate/${base}/${quote}?date=${date}`
  );
  
  if (!response.ok) {
    throw new Error(`Historical lookup failed: ${response.statusText}`);
  }
  
  const data = await response.json();
  return data.rate;
}

// Usage
const rate = await getHistoricalRate('EUR', 'USD', '2024-01-15');
```

#### Time Series with Monthly Grouping
```typescript
async function getTimeSeries(
  base: string,
  quote: string,
  from: string,
  to: string,
  group?: 'day' | 'week' | 'month' | 'year'
): Promise<any> {
  const params = new URLSearchParams({
    base,
    quotes: quote,
    from,
    to
  });
  
  if (group) {
    params.append('group', group);
  }
  
  const response = await fetch(`${API_BASE}/rates?${params}`);
  return response.json();
}

// Usage - monthly averages for 2024
const series = await getTimeSeries('EUR', 'USD', '2024-01-01', '2024-12-31', 'month');
```

### Python

#### Basic Rate Fetching
```python
import requests
from typing import Dict, Optional

API_BASE = 'https://api.frankfurter.dev/v2'

def get_latest_rates(base: str = 'EUR') -> Dict:
    """Fetch latest exchange rates."""
    response = requests.get(
        f'{API_BASE}/rates',
        params={'base': base},
        timeout=30
    )
    response.raise_for_status()
    return response.json()

# Usage
rates = get_latest_rates('USD')
print(rates['rates']['EUR'])  # USD to EUR rate
```

#### Currency Conversion Function
```python
def convert_currency(amount: float, from_curr: str, to_curr: str) -> float:
    """Convert amount from one currency to another."""
    response = requests.get(
        f'{API_BASE}/rate/{from_curr}/{to_curr}',
        timeout=30
    )
    response.raise_for_status()
    data = response.json()
    return amount * data['rate']

# Usage
result = convert_currency(100, 'EUR', 'USD')
print(f'100 EUR = {result:.2f} USD')
```

#### Historical Lookup with Error Handling
```python
from datetime import datetime

def get_historical_rate(base: str, quote: str, date: str) -> Optional[float]:
    """
    Get historical exchange rate for a specific date.
    
    Args:
        base: Base currency code (e.g., 'EUR')
        quote: Quote currency code (e.g., 'USD')
        date: Date in YYYY-MM-DD format
    
    Returns:
        Exchange rate or None if not available
    """
    try:
        response = requests.get(
            f'{API_BASE}/rate/{base}/{quote}',
            params={'date': date},
            timeout=30
        )
        
        if response.status_code == 404:
            return None  # Rate not available for this date
        
        response.raise_for_status()
        return response.json()['rate']
    except requests.exceptions.RequestException as e:
        print(f'Error fetching rate: {e}')
        return None

# Usage
rate = get_historical_rate('EUR', 'USD', '2024-01-15')
if rate:
    print(f'Rate on 2024-01-15: {rate}')
else:
    print('Rate not available for this date')
```

#### Batch Conversion
```python
def convert_to_multiple(amount: float, base: str, targets: list) -> Dict[str, float]:
    """Convert amount to multiple currencies at once."""
    response = requests.get(
        f'{API_BASE}/rates',
        params={
            'base': base,
            'quotes': ','.join(targets)
        },
        timeout=30
    )
    response.raise_for_status()
    data = response.json()
    
    return {
        currency: amount * rate
        for currency, rate in data['rates'].items()
    }

# Usage
conversions = convert_to_multiple(1000, 'EUR', ['USD', 'GBP', 'JPY', 'CHF'])
for curr, amount in conversions.items():
    print(f'1000 EUR = {amount:.2f} {curr}')
```

#### CSV Output Handling
```python
import csv
from io import StringIO

def get_rates_csv(base: str = 'EUR') -> list:
    """Fetch rates in CSV format."""
    response = requests.get(
        f'{API_BASE}/rates.csv',
        params={'base': base},
        headers={'Accept': 'text/csv'},
        timeout=30
    )
    response.raise_for_status()
    
    csv_content = StringIO(response.text)
    reader = csv.DictReader(csv_content)
    return list(reader)

# Usage
csv_rates = get_rates_csv('USD')
for row in csv_rates:
    print(f"{row['currency']}: {row['rate']}")
```

### Ruby

#### Basic Rate Fetching
```ruby
require 'net/http'
require 'json'

API_BASE = 'https://api.frankfurter.dev/v2'

def get_latest_rates(base = 'EUR')
  uri = URI("#{API_BASE}/rates")
  uri.query = URI.encode_www_form('base' => base)
  
  response = Net::HTTP.get_response(uri)
  
  unless response.is_a?(Net::HTTPSuccess)
    raise "API error: #{response.code} #{response.message}"
  end
  
  JSON.parse(response.body)
end

# Usage
rates = get_latest_rates('USD')
puts rates['rates']['EUR']  # USD to EUR rate
```

#### Currency Conversion Function
```ruby
require 'net/http'
require 'json'

def convert_currency(amount, from_curr, to_curr)
  uri = URI("#{API_BASE}/rate/#{from_curr}/#{to_curr}")
  
  response = Net::HTTP.get_response(uri)
  
  unless response.is_a?(Net::HTTPSuccess)
    raise "Conversion failed: #{response.code} #{response.message}"
  end
  
  data = JSON.parse(response.body)
  amount * data['rate']
end

# Usage
result = convert_currency(100, 'EUR', 'USD')
puts "100 EUR = %.2f USD" % result
```

#### Historical Rate with HTTParty (using gem)
```ruby
require 'httparty'

class FrankfurterClient
  include HTTParty
  base_uri 'https://api.frankfurter.dev/v2'
  
  def self.historical_rate(base, quote, date)
    response = get("/rate/#{base}/#{quote}", query: { date: date })
    
    if response.code == 404
      return nil
    elsif !response.success?
      raise "API error: #{response.code}"
    end
    
    response['rate']
  end
  
  def self.time_series(base, quote, from_date, to_date, group = nil)
    params = {
      base: base,
      quotes: quote,
      from: from_date,
      to: to_date
    }
    params[:group] = group if group
    
    get('/rates', query: params)
  end
end

# Usage
rate = FrankfurterClient.historical_rate('EUR', 'USD', '2024-01-15')
puts "Historical rate: #{rate}" if rate
```

#### Multi-Currency Conversion
```ruby
def convert_to_multiple_currencies(amount, base_currency, target_currencies)
  uri = URI("#{API_BASE}/rates")
  uri.query = URI.encode_www_form(
    'base' => base_currency,
    'quotes' => target_currencies.join(',')
  )
  
  response = Net::HTTP.get_response(uri)
  
  unless response.is_a?(Net::HTTPSuccess)
    raise "API error: #{response.code}"
  end
  
  data = JSON.parse(response.body)
  
  data['rates'].transform_values { |rate| amount * rate }
end

# Usage
conversions = convert_to_multiple_currencies(1000, 'EUR', ['USD', 'GBP', 'JPY'])
conversions.each do |currency, amount|
  puts "1000 EUR = %.2f #{currency}" % amount
end
```

## Common Use Cases

### Real-Time Currency Conversion
Use the `/v2/rate/{base}/{quote}` endpoint for single conversions. Cache results for 5-15 minutes to reduce API calls.

### Multi-Currency Dashboard
Use `/v2/rates` with `quotes` parameter to fetch only needed currencies. Improves response time and reduces data transfer.

### Historical Exchange Rate Analysis
Use `/v2/rates?from=&to=` for time series data. Add `group=month` or `group=year` for trend analysis without daily noise.

### Financial Compliance
Use `providers` parameter to get rates from specific sources (ECB, FED, etc.) instead of blended rates for regulatory compliance.

### Data Import/Export
Use `.csv` suffix or `Accept: text/csv` header for spreadsheet integration. Use `Accept: application/x-ndjson` for streaming large historical datasets.

### Weekend/Holiday Handling
When requesting historical rates for dates without trading (weekends, holidays), Frankfurter returns the last available rate. Handle this by checking the returned `date` field against your requested date.

## Best Practices

### API Usage
- **Limit response size**: Always use `quotes` parameter to request only needed currencies
- **Use appropriate output format**: JSON for small responses, NDJSON for large time series, CSV for spreadsheet imports
- **Cache responses**: Rates update daily; cache for reasonable periods (e.g., hourly) to reduce API load
- **Handle rate limiting**: Implement exponential backoff for retries
- **Validate currency codes**: Check against `/v2/currencies` before API calls to avoid 404 errors

### Conversion Accuracy
- **Store rates as received**: Do not round intermediate calculations
- **Round final results only**: Use `.toFixed(2)` or equivalent only for display
- **Watch for floating-point issues**: Use decimal arithmetic libraries for financial calculations in production

### Error Handling
```javascript
// Comprehensive error handling pattern
async function safeApiCall(url) {
  try {
    const response = await fetch(url);
    
    if (!response.ok) {
      const error = await response.json();
      
      if (response.status === 404) {
        throw new Error(`Currency not found: ${error.message}`);
      } else if (response.status === 400) {
        throw new Error(`Invalid request: ${error.message}`);
      } else if (response.status === 422) {
        throw new Error(`Unprocessable request: ${error.message}`);
      } else {
        throw new Error(`API error: ${error.message}`);
      }
    }
    
    return await response.json();
  } catch (error) {
    if (error.name === 'TypeError') {
      throw new Error('Network error: Check internet connection');
    }
    throw error;
  }
}
```

### Production Considerations
- **Set reasonable timeouts**: 30 seconds is sufficient for most queries
- **Implement retry logic**: Use exponential backoff for 5xx errors
- **Log API responses**: For debugging, but never log sensitive user data
- **Monitor API status**: Frankfurter status page at https://frankfurter.instatus.com/

## Edge Cases

### Invalid Currency Codes
Requesting non-existent currencies returns HTTP 404:
```json
{
  "message": "Could not find currency XYZ"
}
```
**Handling**: Validate currency codes against `/v2/currencies` before API calls, or catch 404 errors gracefully.

### Missing Historical Data
Some dates may lack data for specific currency pairs, especially for newer currencies or discontinued ones.
**Handling**: Check the returned `date` field; if it differs from your request, the API returned the nearest available rate.

### Weekend and Holiday Gaps
Frankfurter returns the most recent available rate for non-trading days. This means Friday rates are returned for Saturday/Sunday requests.
**Handling**: The API handles this automatically, but be aware when analyzing time series data.

### Large Response Handling
Time series spanning years can return very large JSON responses.
**Handling**: 
- Use NDJSON format (`Accept: application/x-ndjson`) to stream line-by-line
- Use grouping (`group=month` or `group=year`) to reduce data points
- Paginate by fetching smaller date ranges

### Provider-Specific Rate Differences
Different data providers may have slightly different rates for the same currency pair on the same date.
**Handling**: Use `providers` parameter to get rates from a specific source for consistency, or accept that blended rates are averages.

### Legacy Currencies
Some currencies (like pre-Euro European currencies) exist in the database but are no longer active.
**Handling**: Use `/v2/currencies?scope=all` to see legacy currencies, but `/v2/currencies` (default) returns only active currencies.

### Date Format Requirements
Frankfurter requires ISO 8601 date format (YYYY-MM-DD). Invalid formats return HTTP 400.
**Handling**: Always format dates properly before API calls:
```javascript
const formattedDate = new Date().toISOString().split('T')[0];  // YYYY-MM-DD
```

### Cross-Origin Requests
Frankfurter supports CORS and can be called directly from browsers without API keys.
**Handling**: No special configuration needed for client-side JavaScript calls.

## Example: Complete Implementation

### Multi-Currency Converter Application

```typescript
// frankfurter-client.ts
const API_BASE = 'https://api.frankfurter.dev/v2';

export class CurrencyConverter {
  private cache: Map<string, { data: any; timestamp: number }> = new Map();
  private cacheDuration = 5 * 60 * 1000; // 5 minutes

  async convert(
    amount: number,
    from: string,
    to: string
  ): Promise<{ amount: number; rate: number; date: string }> {
    const cacheKey = `rate-${from}-${to}`;
    const cached = this.cache.get(cacheKey);
    
    if (cached && Date.now() - cached.timestamp < this.cacheDuration) {
      return {
        amount: amount * cached.data.rate,
        rate: cached.data.rate,
        date: cached.data.date
      };
    }

    const response = await fetch(`${API_BASE}/rate/${from}/${to}`);
    
    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.message);
    }

    const data = await response.json();
    
    this.cache.set(cacheKey, { data, timestamp: Date.now() });
    
    return {
      amount: amount * data.rate,
      rate: data.rate,
      date: data.date
    };
  }

  async getSupportedCurrencies(): Promise<string[]> {
    const response = await fetch(`${API_BASE}/currencies`);
    const data = await response.json();
    return Object.keys(data.currencies);
  }
}

// Usage
const converter = new CurrencyConverter();

// Validate currency before conversion
const supported = await converter.getSupportedCurrencies();
if (!supported.includes('XYZ')) {
  throw new Error('Unsupported currency');
}

// Perform conversion
const result = await converter.convert(100, 'EUR', 'USD');
console.log(`100 EUR = ${result.amount.toFixed(2)} USD (rate: ${result.rate})`);
```

This implementation demonstrates:
- Caching for performance
- Error handling
- Currency validation
- Clean API client design

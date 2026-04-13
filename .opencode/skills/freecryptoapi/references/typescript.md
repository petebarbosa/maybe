# TypeScript/JavaScript Examples for FreeCryptoAPI

Complete TypeScript/JavaScript implementation examples for FreeCryptoAPI free tier endpoints.

## Setup and Authentication

```typescript
// Get API key from environment variable
const API_KEY = process.env.FREECRYPTO_API_KEY;
const API_BASE = "https://api.freecryptoapi.com/v1";

if (!API_KEY) {
    throw new Error("FREECRYPTO_API_KEY environment variable not set");
}

const headers = {
    "Authorization": `Bearer ${API_KEY}`,
    "Content-Type": "application/json"
};

// TypeScript Interfaces
interface CryptoData {
    symbol: string;
    price: number;
    change_24h: number;
    change_percentage_24h: number;
    market_cap: number;
    volume: number;
}

interface ConversionResult {
    from: string;
    to: string;
    amount: number;
    converted_amount: number;
    rate: number;
}
```

## FREE Tier Examples

### Get Live Cryptocurrency Data

```typescript
async function getCryptoData(symbol: string): Promise<CryptoData | null> {
    try {
        const response = await fetch(
            `${API_BASE}/getData?symbol=${encodeURIComponent(symbol)}`,
            { headers }
        );
        
        if (response.status === 404) {
            return null;
        }
        
        if (response.status === 429) {
            throw new Error("Rate limit exceeded");
        }
        
        if (!response.ok) {
            throw new Error(`HTTP ${response.status}`);
        }
        
        return await response.json();
    } catch (error) {
        console.error("Error:", error);
        return null;
    }
}

// Usage
const btcData = await getCryptoData("BTC");
if (btcData) {
    console.log(`BTC Price: $${btcData.price.toLocaleString()}`);
    console.log(`24h Change: ${btcData.change_percentage_24h}%`);
}
```

### Get Multiple Cryptocurrencies

```typescript
async function getMultipleCryptos(
    symbols: string[]
): Promise<Record<string, CryptoData>> {
    const symbolString = symbols.join("+");
    
    try {
        const response = await fetch(
            `${API_BASE}/getData?symbol=${encodeURIComponent(symbolString)}`,
            { headers }
        );
        
        if (!response.ok) {
            throw new Error(`HTTP ${response.status}`);
        }
        
        const data = await response.json();
        const results = Array.isArray(data) ? data : [data];
        
        return results.reduce((acc, item) => {
            acc[item.symbol] = item;
            return acc;
        }, {} as Record<string, CryptoData>);
    } catch (error) {
        console.error("Error:", error);
        return {};
    }
}

// Usage
const portfolio = await getMultipleCryptos(["BTC", "ETH", "SOL"]);
for (const [symbol, data] of Object.entries(portfolio)) {
    console.log(`${symbol}: $${data.price.toFixed(2)}`);
}
```

### Cryptocurrency Conversion (Crypto-to-Crypto)

**Important**: FREE tier only supports crypto-to-crypto. Use USDT as USD-pegged alternative.

```typescript
async function convertCrypto(
    fromSymbol: string,
    toSymbol: string,
    amount: number
): Promise<number | null> {
    try {
        const params = new URLSearchParams({
            from: fromSymbol,
            to: toSymbol,
            amount: amount.toString()
        });
        
        const response = await fetch(
            `${API_BASE}/getConversion?${params}`,
            { headers }
        );
        
        if (response.status === 404) {
            return null;
        }
        
        if (!response.ok) {
            throw new Error(`HTTP ${response.status}`);
        }
        
        const result: ConversionResult = await response.json();
        return result.converted_amount;
    } catch (error) {
        console.error("Error:", error);
        return null;
    }
}

// Usage - FREE tier (crypto-to-crypto)
const ethAmount = await convertCrypto("BTC", "ETH", 1.0);
if (ethAmount) {
    console.log(`1 BTC = ${ethAmount:.6f} ETH`);
}

// Use USDT as USD alternative
const usdtAmount = await convertCrypto("ETH", "USDT", 1.0);
if (usdtAmount) {
    console.log(`1 ETH = ${usdtAmount:.2f} USDT`);
}
```

### Get Exchange-Specific Data

```typescript
async function getExchangeData(exchange: string): Promise<any | null> {
    try {
        const response = await fetch(
            `${API_BASE}/getExchange?exchange=${encodeURIComponent(exchange)}`,
            { headers }
        );
        
        if (!response.ok) {
            throw new Error(`HTTP ${response.status}`);
        }
        
        return await response.json();
    } catch (error) {
        console.error("Error:", error);
        return null;
    }
}

// Usage
const binanceData = await getExchangeData("binance");
if (binanceData) {
    console.log(`Pairs on Binance: ${binanceData.symbols.length}`);
}
```

## Complete Working Example

```typescript
class FreeCryptoTracker {
    private apiKey: string;
    private baseUrl: string = "https://api.freecryptoapi.com/v1";
    private headers: HeadersInit;
    private cache: Map<string, { data: any; timestamp: number }> = new Map();
    private cacheDuration: number = 60000; // 60 seconds

    constructor() {
        this.apiKey = process.env.FREECRYPTO_API_KEY || "";
        if (!this.apiKey) {
            throw new Error("FREECRYPTO_API_KEY not set");
        }
        
        this.headers = {
            "Authorization": `Bearer ${this.apiKey}`,
            "Content-Type": "application/json"
        };
    }

    private getCached(key: string): any | null {
        const cached = this.cache.get(key);
        if (cached && Date.now() - cached.timestamp < this.cacheDuration) {
            return cached.data;
        }
        return null;
    }

    private setCached(key: string, data: any): void {
        this.cache.set(key, { data, timestamp: Date.now() });
    }

    async getPrice(symbol: string): Promise<CryptoData | null> {
        const cacheKey = `price_${symbol}`;
        const cached = this.getCached(cacheKey);
        if (cached) return cached;

        try {
            const response = await fetch(
                `${this.baseUrl}/getData?symbol=${encodeURIComponent(symbol)}`,
                { headers: this.headers }
            );

            if (response.status === 404) return null;
            if (!response.ok) throw new Error(`HTTP ${response.status}`);

            const data = await response.json();
            this.setCached(cacheKey, data);
            return data;
        } catch (error) {
            console.error("Error:", error);
            return null;
        }
    }

    async getPortfolioValue(
        holdings: Record<string, number>
    ): Promise<number | null> {
        const symbols = Object.keys(holdings);
        if (symbols.length === 0) return 0;

        try {
            const symbolString = symbols.join("+");
            const response = await fetch(
                `${this.baseUrl}/getData?symbol=${encodeURIComponent(symbolString)}`,
                { headers: this.headers }
            );

            if (!response.ok) throw new Error(`HTTP ${response.status}`);

            const data = await response.json();
            const results = Array.isArray(data) ? data : [data];
            const prices: Record<string, number> = {};
            
            results.forEach(item => {
                prices[item.symbol] = item.price;
            });

            return Object.entries(holdings).reduce((total, [symbol, amount]) => {
                return total + (amount * (prices[symbol] || 0));
            }, 0);
        } catch (error) {
            console.error("Error:", error);
            return null;
        }
    }

    async convert(
        fromSymbol: string,
        toSymbol: string,
        amount: number
    ): Promise<number | null> {
        try {
            const params = new URLSearchParams({
                from: fromSymbol,
                to: toSymbol,
                amount: amount.toString()
            });

            const response = await fetch(
                `${this.baseUrl}/getConversion?${params}`,
                { headers: this.headers }
            );

            if (response.status === 404) return null;
            if (!response.ok) throw new Error(`HTTP ${response.status}`);

            const result = await response.json();
            return result.converted_amount;
        } catch (error) {
            console.error("Error:", error);
            return null;
        }
    }
}

// Usage
async function main() {
    const tracker = new FreeCryptoTracker();

    const portfolio = {
        "BTC": 0.5,
        "ETH": 2.0,
        "SOL": 10.0
    };

    console.log("Portfolio Tracker (Free Tier)");
    console.log("=" * 40);

    // Show individual prices
    for (const symbol of Object.keys(portfolio)) {
        const data = await tracker.getPrice(symbol);
        if (data) {
            const value = portfolio[symbol] * data.price;
            console.log(`${symbol}: ${portfolio[symbol]} × $${data.price.toLocaleString()} = $${value.toLocaleString()}`);
        }
    }

    // Show total
    const total = await tracker.getPortfolioValue(portfolio);
    if (total) {
        console.log(`\nTotal Value: $${total.toLocaleString()}`);
    }

    // Crypto-to-crypto conversion
    const btcToEth = await tracker.convert("BTC", "ETH", 1.0);
    if (btcToEth) {
        console.log(`\n1 BTC = ${btcToEth.toFixed(6)} ETH`);
    }
}

main();
```

See [python.md](python.md) for Python examples.
See [ruby.md](ruby.md) for Ruby examples.
See [free-vs-pro.md](free-vs-pro.md) for tier information.

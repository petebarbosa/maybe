# Ruby Examples for FreeCryptoAPI

Complete Ruby implementation examples for FreeCryptoAPI free tier endpoints.

## Setup and Authentication

```ruby
require 'net/http'
require 'json'
require 'uri'

# Get API key from environment variable
API_KEY = ENV['FREECRYPTO_API_KEY']
API_BASE = 'https://api.freecryptoapi.com/v1'

raise 'FREECRYPTO_API_KEY environment variable not set' unless API_KEY

headers = {
    'Authorization' => "Bearer #{API_KEY}",
    'Content-Type' => 'application/json'
}
```

## FREE Tier Examples

### Get Live Cryptocurrency Data

```ruby
def get_crypto_data(symbol)
    uri = URI("#{API_BASE}/getData")
    uri.query = URI.encode_www_form('symbol' => symbol)
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 30
    
    request = Net::HTTP::Get.new(uri)
    headers.each { |key, value| request[key] = value }
    
    response = http.request(request)
    
    return nil if response.code == '404'
    raise 'Rate limit exceeded' if response.code == '429'
    
    unless response.is_a?(Net::HTTPSuccess)
        raise "API error: #{response.code} #{response.message}"
    end
    
    JSON.parse(response.body)
rescue => e
    puts "Error: #{e.message}"
    nil
end

# Usage
btc_data = get_crypto_data('BTC')
if btc_data
    puts "BTC Price: $#{btc_data['price']}"
    puts "24h Change: #{btc_data['change_percentage_24h']}%"
end
```

### Get Multiple Cryptocurrencies

```ruby
def get_multiple_cryptos(symbols)
    symbol_string = symbols.join('+')
    uri = URI("#{API_BASE}/getData")
    uri.query = URI.encode_www_form('symbol' => symbol_string)
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 30
    
    request = Net::HTTP::Get.new(uri)
    headers.each { |key, value| request[key] = value }
    
    response = http.request(request)
    
    unless response.is_a?(Net::HTTPSuccess)
        puts "Error: #{response.code}"
        return {}
    end
    
    data = JSON.parse(response.body)
    results = data.is_a?(Array) ? data : [data]
    results.to_h { |item| [item['symbol'], item] }
rescue => e
    puts "Error: #{e.message}"
    {}
end

# Usage
portfolio = get_multiple_cryptos(['BTC', 'ETH', 'SOL'])
portfolio.each do |symbol, data|
    puts "#{symbol}: $#{data['price'].round(2)}"
end
```

### Cryptocurrency Conversion (Crypto-to-Crypto)

**Important**: FREE tier only supports crypto-to-crypto. Use USDT as USD alternative.

```ruby
def convert_crypto(from_symbol, to_symbol, amount)
    uri = URI("#{API_BASE}/getConversion")
    uri.query = URI.encode_www_form(
        'from' => from_symbol,
        'to' => to_symbol,
        'amount' => amount.to_s
    )
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 30
    
    request = Net::HTTP::Get.new(uri)
    headers.each { |key, value| request[key] = value }
    
    response = http.request(request)
    
    return nil if response.code == '404'
    
    unless response.is_a?(Net::HTTPSuccess)
        raise "Conversion error: #{response.code}"
    end
    
    result = JSON.parse(response.body)
    result['converted_amount']
rescue => e
    puts "Conversion error: #{e.message}"
    nil
end

# Usage - FREE tier (crypto-to-crypto)
eth_amount = convert_crypto('BTC', 'ETH', 1.0)
puts "1 BTC = #{eth_amount.round(6)} ETH" if eth_amount

# Use USDT as USD-pegged alternative
usdt_amount = convert_crypto('ETH', 'USDT', 1.0)
puts "1 ETH = #{usdt_amount.round(2)} USDT" if usdt_amount
```

### Get Exchange-Specific Data

```ruby
def get_exchange_data(exchange)
    uri = URI("#{API_BASE}/getExchange")
    uri.query = URI.encode_www_form('exchange' => exchange)
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 30
    
    request = Net::HTTP::Get.new(uri)
    headers.each { |key, value| request[key] = value }
    
    response = http.request(request)
    
    unless response.is_a?(Net::HTTPSuccess)
        puts "Error: #{response.code}"
        return nil
    end
    
    JSON.parse(response.body)
rescue => e
    puts "Error: #{e.message}"
    nil
end

# Usage
binance_data = get_exchange_data('binance')
if binance_data
    puts "Available pairs: #{binance_data['symbols'].length}"
end
```

## Complete Working Example

```ruby
require 'net/http'
require 'json'
require 'uri'
require 'time'

class FreeCryptoTracker
    def initialize
        @api_key = ENV['FREECRYPTO_API_KEY']
        @base_url = 'https://api.freecryptoapi.com/v1'
        @headers = {
            'Authorization' => "Bearer #{@api_key}",
            'Content-Type' => 'application/json'
        }
        @cache = {}
        @cache_duration = 60  # seconds
    end
    
    def get_cached(key)
        return nil unless @cache[key]
        timestamp, data = @cache[key]
        return nil if Time.now.to_i - timestamp > @cache_duration
        data
    end
    
    def set_cached(key, data)
        @cache[key] = [Time.now.to_i, data]
    end
    
    def get_price(symbol)
        cache_key = "price_#{symbol}"
        cached = get_cached(cache_key)
        return cached if cached
        
        uri = URI("#{@base_url}/getData")
        uri.query = URI.encode_www_form('symbol' => symbol)
        
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.read_timeout = 30
        
        request = Net::HTTP::Get.new(uri)
        @headers.each { |key, value| request[key] = value }
        
        response = http.request(request)
        return nil if response.code == '404'
        
        unless response.is_a?(Net::HTTPSuccess)
            puts "Error: #{response.code}"
            return nil
        end
        
        data = JSON.parse(response.body)
        set_cached(cache_key, data)
        data
    rescue => e
        puts "Error: #{e.message}"
        nil
    end
    
    def get_portfolio_value(holdings)
        symbols = holdings.keys
        return 0.0 if symbols.empty?
        
        symbol_string = symbols.join('+')
        uri = URI("#{@base_url}/getData")
        uri.query = URI.encode_www_form('symbol' => symbol_string)
        
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.read_timeout = 30
        
        request = Net::HTTP::Get.new(uri)
        @headers.each { |key, value| request[key] = value }
        
        response = http.request(request)
        
        unless response.is_a?(Net::HTTPSuccess)
            puts "Error: #{response.code}"
            return nil
        end
        
        data = JSON.parse(response.body)
        results = data.is_a?(Array) ? data : [data]
        prices = results.to_h { |item| [item['symbol'], item['price']] }
        
        holdings.sum { |symbol, amount| amount * (prices[symbol] || 0) }
    rescue => e
        puts "Error: #{e.message}"
        nil
    end
    
    def convert(from_symbol, to_symbol, amount)
        uri = URI("#{@base_url}/getConversion")
        uri.query = URI.encode_www_form(
            'from' => from_symbol,
            'to' => to_symbol,
            'amount' => amount.to_s
        )
        
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.read_timeout = 30
        
        request = Net::HTTP::Get.new(uri)
        @headers.each { |key, value| request[key] = value }
        
        response = http.request(request)
        return nil if response.code == '404'
        
        unless response.is_a?(Net::HTTPSuccess)
            puts "Error: #{response.code}"
            return nil
        end
        
        result = JSON.parse(response.body)
        result['converted_amount']
    rescue => e
        puts "Error: #{e.message}"
        nil
    end
end

# Usage
if __FILE__ == $0
    tracker = FreeCryptoTracker.new
    
    portfolio = {
        'BTC' => 0.5,
        'ETH' => 2.0,
        'SOL' => 10.0
    }
    
    puts "Portfolio Tracker (Free Tier)"
    puts "=" * 40
    
    # Show individual prices
    portfolio.each do |symbol, amount|
        data = tracker.get_price(symbol)
        if data
            value = amount * data['price']
            puts "#{symbol}: #{amount} × $#{data['price']} = $#{value.round(2)}"
        end
    end
    
    # Show total
    total = tracker.get_portfolio_value(portfolio)
    puts "\nTotal Value: $#{total.round(2)}" if total
    
    # Crypto-to-crypto conversion
    btc_to_eth = tracker.convert('BTC', 'ETH', 1.0)
    puts "\n1 BTC = #{btc_to_eth.round(6)} ETH" if btc_to_eth
end
```

See [python.md](python.md) for Python examples.
See [typescript.md](typescript.md) for TypeScript examples.
See [free-vs-pro.md](free-vs-pro.md) for tier information.

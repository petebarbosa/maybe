# Later Fixes

## Unrelated failing tests (not part of exchange-rate provider migration)

These failures were observed while running the broader test subset after the Frankfurter/FreeCrypto exchange-rate migration:

- `test/models/holding_test.rb`
- `test/models/account/market_data_importer_test.rb`

Error seen:

- `PG::UndefinedFunction: operator does not exist: bigint = character varying`

Primary stack locations:

- `app/models/holding.rb:41`
- `app/models/account/market_data_importer.rb:48`

Notes:

- These failures appear to be pre-existing query/type mismatch issues unrelated to the exchange-rate provider switch.
- Exchange-rate provider tests and importer flow for fiat/crypto behavior pass after migration changes.

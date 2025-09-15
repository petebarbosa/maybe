class AddSearchVectorToSecurities < ActiveRecord::Migration[7.2]
  def change
    # SQLite doesn't support tsvector or full-text search like PostgreSQL
    # Skip this migration for SQLite - search can be implemented in application code
  end
end

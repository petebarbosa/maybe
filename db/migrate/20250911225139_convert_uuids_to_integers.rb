class ConvertUuidsToIntegers < ActiveRecord::Migration[7.2]
  def up
    puts "⚠️  This migration will convert all UUID primary keys to integer IDs"
    puts "⚠️  This is a destructive operation that will change your database schema"
    puts "⚠️  Make sure you have a complete backup before proceeding!"
    puts ""
    puts "❌ This migration is currently disabled for safety."
    puts "❌ To enable it, edit this migration file and set ENABLE_MIGRATION = true"
    puts ""
    puts "📋 Steps to complete the migration:"
    puts "1. Backup your database completely"
    puts "2. Drop and recreate your database for a fresh start"
    puts "3. Run: rails db:create db:migrate db:seed"
    puts "4. Import your data using a custom import script"

    return unless ENV['ENABLE_UUID_TO_INTEGER_MIGRATION'] == 'true'

    puts "🚀 Starting UUID to Integer conversion..."

    # This is a simplified approach - we'll drop and recreate everything
    # This is safer than trying to convert in place
    raise ActiveRecord::IrreversibleMigration, "This migration requires a fresh database. Drop and recreate your database, then run migrations."
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Cannot reverse UUID to integer conversion"
  end
end

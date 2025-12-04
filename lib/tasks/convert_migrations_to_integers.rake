namespace :db do
  desc "Convert all migration files from UUID to integer IDs"
  task convert_migrations_to_integers: :environment do
    puts "🔄 Converting migration files from UUID to integer IDs..."

    migration_dir = Rails.root.join("db", "migrate")
    converted_count = 0

    Dir.glob("#{migration_dir}/*.rb").each do |file_path|
      lines = File.readlines(file_path)
      original_lines = lines.dup
      modified = false

      lines.map! do |line|
        original_line = line.dup

        # Convert create_table with UUID id
        if line.match?(/create_table\s+:\w+,\s*id:\s*:uuid/)
          line = line.gsub(/,\s*id:\s*:uuid/, "")
          line = line.gsub(/, default: -> \{ "gen_random_uuid\(\)" \}/, "")
          line = line.gsub(/, force: :cascade/, "")
        end

        # Convert references with UUID type
        if line.match?(/t\.references.*type:\s*:uuid/) || line.match?(/add_reference.*type:\s*:uuid/)
          line = line.gsub(/,\s*type:\s*:uuid/, "")
        end

        # Remove/convert PostgreSQL-specific patterns
        line = line.gsub(/, default: -> \{ "gen_random_uuid\(\)" \}/, "")
        line = line.gsub(/, force: :cascade/, "")

        # Convert jsonb to json for SQLite
        line = line.gsub(/t\.jsonb/, "t.json")

        # Convert UUID columns to string (SQLite doesn't have native UUID type)
        line = line.gsub(/t\.uuid/, "t.string")

        # Remove PostgreSQL array types (SQLite doesn't support them)
        line = line.gsub(/, array: true/, "")

        # Remove PostgreSQL-specific index features
        line = line.gsub(/, using: :gin/, "")
        line = line.gsub(/, order: \{[^}]+\}/, "")

        # Remove PostgreSQL WHERE clauses that use advanced syntax
        if line.match?(/where:.*DESC NULLS LAST/) || line.match?(/where:.*ASC NULLS LAST/)
          line = line.gsub(/, where: "[^"]*"/, "")
        end

        # Convert PostgreSQL enums to strings
        if line.match?(/create_enum/)
          line = "    # #{line.strip} # SQLite doesn't support enums"
        end

        if line.match?(/t\.enum/)
          line = line.gsub(/t\.enum/, "t.string")
          line = line.gsub(/, enum_type: :\w+/, "")
        end

        modified = true if line != original_line
        line
      end

      # Write back if changed
      if modified
        File.write(file_path, lines.join)
        puts "✅ Converted #{File.basename(file_path)}"
        converted_count += 1
      end
    end

    puts "\n🎉 Conversion complete!"
    puts "📊 Converted #{converted_count} migration files"
    puts "\n📋 Next steps:"
    puts "1. Drop your current database: rails db:drop"
    puts "2. Create a fresh database: rails db:create"
    puts "3. Run all migrations: rails db:migrate"
    puts "4. Seed the database: rails db:seed"
  end

  desc "Backup current database before UUID conversion"
  task backup_before_conversion: :environment do
    timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
    backup_file = Rails.root.join("tmp", "backup_before_uuid_conversion_#{timestamp}.sqlite3")

    if File.exist?(Rails.configuration.database_configuration[Rails.env]["database"])
      FileUtils.cp(
        Rails.configuration.database_configuration[Rails.env]["database"],
        backup_file
      )
      puts "✅ Database backed up to: #{backup_file}"
    else
      puts "❌ No database file found to backup"
    end
  end

  desc "Full UUID to Integer conversion process"
  task convert_uuid_to_integers: :environment do
    puts "🚀 Starting full UUID to Integer conversion process..."
    puts "⚠️  This will modify your migration files and recreate your database"
    puts "⚠️  Make sure you have backed up any important data!"
    puts ""

    # Step 1: Backup
    puts "📦 Step 1: Creating backup..."
    Rake::Task["db:backup_before_conversion"].invoke

    # Step 2: Convert migrations
    puts "\n🔄 Step 2: Converting migration files..."
    Rake::Task["db:convert_migrations_to_integers"].invoke

    # Step 3: Recreate database
    puts "\n🗃️  Step 3: Recreating database..."
    Rake::Task["db:drop"].invoke
    Rake::Task["db:create"].invoke
    Rake::Task["db:migrate"].invoke

    # Step 4: Seed if seeds exist
    if File.exist?(Rails.root.join("db", "seeds.rb"))
      puts "\n🌱 Step 4: Seeding database..."
      Rake::Task["db:seed"].invoke
    end

    puts "\n🎉 UUID to Integer conversion complete!"
    puts "✅ Your database now uses integer IDs instead of UUIDs"
    puts "✅ All migration files have been updated"
    puts "✅ Database has been recreated with integer IDs"
  end
end

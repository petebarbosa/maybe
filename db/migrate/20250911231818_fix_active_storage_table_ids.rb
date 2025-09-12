class FixActiveStorageTableIds < ActiveRecord::Migration[7.2]
  def up
    # Drop and recreate Active Storage tables with proper integer IDs for SQLite
    # This fixes the "Unknown type 'id' for column 'id'" issue in schema.rb

    drop_table :active_storage_variant_records, if_exists: true
    drop_table :active_storage_attachments, if_exists: true
    drop_table :active_storage_blobs, if_exists: true

    # Recreate Active Storage tables with integer IDs
    create_table :active_storage_blobs, force: :cascade do |t|
      t.string :key, null: false
      t.string :filename, null: false
      t.string :content_type
      t.text :metadata
      t.string :service_name, null: false
      t.bigint :byte_size, null: false
      t.string :checksum
      t.datetime :created_at, null: false

      t.index [ :key ], unique: true
    end

    create_table :active_storage_attachments, force: :cascade do |t|
      t.string :name, null: false
      t.references :record, null: false, polymorphic: true, index: false
      t.references :blob, null: false, foreign_key: { to_table: :active_storage_blobs }, index: false
      t.datetime :created_at, null: false

      t.index [ :record_type, :record_id, :name, :blob_id ], name: "index_active_storage_attachments_uniqueness", unique: true
      t.index [ :blob_id ], name: "index_active_storage_attachments_on_blob_id"
    end

    create_table :active_storage_variant_records, force: :cascade do |t|
      t.references :blob, null: false, index: false, foreign_key: { to_table: :active_storage_blobs }
      t.string :variation_digest, null: false

      t.index [ :blob_id, :variation_digest ], name: "index_active_storage_variant_records_uniqueness", unique: true
    end
  end

  def down
    drop_table :active_storage_variant_records, if_exists: true
    drop_table :active_storage_attachments, if_exists: true
    drop_table :active_storage_blobs, if_exists: true
  end
end

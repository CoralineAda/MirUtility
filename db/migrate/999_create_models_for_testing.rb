class CreateModelsForTesting < ActiveRecord::Migration
  def self.up
    create_table :primaries do |t|
      t.string  :name
    end
    create_table :secondaries do |t|
      t.string  :name
      t.integer :primary_id
    end
  end

  def self.down
    drop_table :primaries
    drop_table :secondaries
  end
end

class CreateRoles < ActiveRecord::Migration
  def self.up
    create_table :roles do |t|
      t.string  :name
      t.timestamps
    end
    add_index :roles, :name    

    Role.create :name => 'Admin'
    Role.create :name => 'Client'
  end

  def self.down
    drop_table :roles
  end
end

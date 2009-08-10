class CreateUsers < ActiveRecord::Migration
	def self.up
		create_table "users", :force => true do |t|
		  t.integer :role_id
			t.column :email,										 :string, :limit => 100
			t.string :first_name
			t.string :last_name
			t.column :crypted_password,					 :string, :limit => 40
			t.column :salt,											 :string, :limit => 40
			t.column :remember_token,						 :string, :limit => 40
			t.column :remember_token_expires_at, :datetime
			t.column :activation_code,					 :string, :limit => 40
			t.column :state,										 :string, :null => :no, :default => 'passive'
			t.column :activated_at,							 :datetime
			t.column :deleted_at,								 :datetime
			t.column :logged_in_at,							 :datetime
      t.timestamps
		end
		add_index :users, :email, :unique => true
	end

	def self.down
		drop_table "users"
	end
end

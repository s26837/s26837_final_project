class CreateDemoKeyUsages < ActiveRecord::Migration[8.0]
  def change
    create_table :demo_key_usages do |t|
      t.integer  :count,          null: false, default: 0
      t.datetime :last_reset_at
      t.timestamps
    end
  end
end

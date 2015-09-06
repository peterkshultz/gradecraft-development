class CreateFlaggedUsers < ActiveRecord::Migration
  def change
    create_table :flagged_users do |t|
      t.references :course, index: true, foreign_key: true
      t.integer :flagger_id, index: true
      t.integer :flagged_id, index: true

      t.timestamps null: false
    end
    add_foreign_key :flagged_users, :users, column: :flagger_id
    add_foreign_key :flagged_users, :users, column: :flagged_id
  end
end

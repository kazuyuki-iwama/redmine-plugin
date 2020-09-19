class CreateTimerecards < ActiveRecord::Migration[5.2]
  def change
    create_table :timecards, if_not_exists: true, primary_key: [:key] do |t|
      t.string :key
      t.date :calender_dt
      t.integer :user_id
      t.datetime :punchin_tm
      t.datetime :punchout_tm
      t.boolean :edit_fg
      t.string :remarks_tx
    end
  end
end

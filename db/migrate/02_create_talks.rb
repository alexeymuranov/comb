class CreateTalks < ActiveRecord::Migration
  def up
    create_table 'talks' do |t|
      t.string  'type'
      t.integer 'duration_minutes'

      t.integer 'participation_id'

      t.string  'title',  :null => false
      t.text    'abstract'
      t.string  'joint_with'
      t.date    'date'
      t.string  'time'

      t.string  'room_or_auditorium'

      t.timestamps
    end

    add_index 'talks', 'participation_id'
    add_index 'talks', ['title', 'participation_id']
  end

  def down
    drop_table 'talks'
  end
end

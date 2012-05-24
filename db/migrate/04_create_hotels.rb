class CreateHotels < ActiveRecord::Migration
  def up
    create_table 'hotels' do |t|
      t.string 'name', :null => false
      t.string 'address'
      t.string 'phone'
      t.string 'web_site'

      t.timestamps
    end
  end

  def down
    drop_table 'hotels'
  end
end

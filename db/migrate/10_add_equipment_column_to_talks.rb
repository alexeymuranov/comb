class AddEquipmentColumnToTalks < ActiveRecord::Migration
  def up
    add_column 'talks', 'equipment', :string, :limit => 255
  end

  def down
    remove_column 'talks', 'equipment'
  end
end

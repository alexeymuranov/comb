class AddWebSiteColumnToParticipants < ActiveRecord::Migration
  def up
    add_column 'participants', 'web_site', :string, :limit => 255
  end

  def down
    remove_column 'participants', 'web_site'
  end
end

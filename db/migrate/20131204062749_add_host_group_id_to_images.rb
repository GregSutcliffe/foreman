class AddHostGroupIdToImages < ActiveRecord::Migration
  def change
    add_column :images, :hostgroup_id, :integer
  end
end

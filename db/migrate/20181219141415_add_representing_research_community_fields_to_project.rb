class AddRepresentingResearchCommunityFieldsToProject < ActiveRecord::Migration[5.2]
  def up
    add_column :projects, :user_group_name, :text

    Project.find_each do |item|
      if item.research?
        item.user_group_name = "Not provided"
        item.save!
      end
    end
  end

  def down
    remove_column :projects, :user_group_name
  end
end

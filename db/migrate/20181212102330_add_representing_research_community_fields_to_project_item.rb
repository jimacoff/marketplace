class AddRepresentingResearchCommunityFieldsToProjectItem < ActiveRecord::Migration[5.2]
  def up
    add_column :project_items, :user_group_name, :text

    ProjectItem.find_each do |item|
      if item.research?
        item.user_group_name = "Not provided"
        item.save!
      end
    end
  end

  def down
    remove_column :project_items, :user_group_name
  end
end

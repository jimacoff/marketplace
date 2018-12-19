class AddRepresentingProjectFieldsToProjectItem < ActiveRecord::Migration[5.2]
  def up
    add_column :project_items, :project_name, :string
    add_column :project_items, :project_website_url, :string

    ProjectItem.find_each do |item|
      if item.project?
        item.project_name = "Not provided"
        item.project_website_url = "https://not.provided"
        item.save!
      end
    end
  end

  def down
    remove_column :project_items, :project_name
    remove_column :project_items, :project_website_url
  end
end

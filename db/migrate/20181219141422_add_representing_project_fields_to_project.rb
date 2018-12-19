class AddRepresentingProjectFieldsToProject < ActiveRecord::Migration[5.2]
  def up
    add_column :projects, :project_name, :string
    add_column :projects, :project_website_url, :string

    Project.find_each do |item|
      if item.project?
        item.project_name = "Not provided"
        item.project_website_url = "https://not.provided"
        item.save!
      end
    end
  end

  def down
    remove_column :projects, :project_name
    remove_column :projects, :project_website_url
  end
end

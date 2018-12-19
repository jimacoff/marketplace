class AddPrivateCompanyFieldsToProjectItem < ActiveRecord::Migration[5.2]
  def up
    add_column :project_items, :company_name, :string
    add_column :project_items, :company_website_url, :string

    ProjectItem.find_each do |item|
      if item.private_company?
        item.company_name = "Not provided"
        item.company_websie_url = "https://not.provided"
        item.save!
      end
    end
  end

  def down
    remove_column :project_items, :company_name
    remove_column :project_items, :company_website_url
  end
end

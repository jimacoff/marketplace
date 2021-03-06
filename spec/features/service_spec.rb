# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Service browsing" do
  include OmniauthHelper

  let(:user) { create(:user) }

  context "as logged in user" do

    before { checkin_sign_in_as(user) }

    scenario "allows to see details" do
      service = create(:service, tag_list: ["my-tag"])

      visit service_path(service)

      expect(body).to have_content service.title
      expect(body).to have_content service.description
      expect(body).to have_content service.tagline
      expect(body).to have_content "my-tag"
    end

    scenario "I see Ask Question" do
      service = create(:service)

      visit service_path(service)

      expect(page).to have_content "Want to ask a question about this service?"

    end

    scenario "I can see question-modal if I click on link", js: true do
      service = create(:service)

      visit service_path(service)

      find("#modal-show").click

      expect(page).to have_css("div#question-modal.show")
    end

    scenario "I can sand message about service", js: true do
      user1, user2 = create_list(:user, 2)
      service = create(:service, contact_emails: [user1.email, user2.email])

      visit service_path(service)

      find("#modal-show").click

      within("#question-modal") do
        fill_in("service_question_text", with: "text")
      end

      expect { click_on "SEND" }.
        to change { ActionMailer::Base.deliveries.count }.by(2)
      expect(page).to have_content("Your message was successfully sended")
    end
  end

  scenario "shows related services" do
    service, related = create_list(:service, 2)
    ServiceRelationship.create!(source: service, target: related)

    visit service_path(service)

    expect(page.body).to have_content "Suggested compatible services"
    expect(page.body).to have_content related.title
  end

  scenario "does not show related services section when no related services" do
    service = create(:service)

    visit service_path(service)

    expect(page.body).to_not have_content "Suggested compatible services"
  end
  context "service has no offers" do
    scenario "service offers section are not displayed" do
      service = create(:service)

      visit service_path(service)

      expect(page.body).not_to have_content("Service offers")
    end
  end

  scenario "show technical parameters in service view" do
    offer = create(:offer, parameters: [{ "id": "id1",
                                          "type": "select",
                                          "label": "Number of CPU Cores",
                                          "config": { "mode": "buttons", "values": [1, 2, 4, 8] },
                                          "value_type": "integer",
                                          "description": "Select number of cores you want" },
                                        { "id": "id2",
                                          "type": "select",
                                          "unit": "GB",
                                          "label": "Amount of RAM per CPU core",
                                          "config": { "mode": "buttons", "values": [1, 2, 4] },
                                          "value_type": "integer",
                                          "description": "Select amount of RAM per core" },
                                        { "id": "id3",
                                          "type": "select",
                                          "unit": "GB",
                                          "label": "Local disk",
                                          "config": { "mode": "buttons", "values": [10, 20, 40] },
                                          "value_type": "integer",
                                          "description": "Amount of local disk space" },
                                        { "id": "id4",
                                          "type": "input",
                                          "label": "Number of VM instances",
                                          "config": { "maximum": 50, "minimum": 1 },
                                          "value_type": "integer",
                                          "description": "Type number of VM instances from 1-50" },
                                        { "id": "id5",
                                          "type": "select",
                                          "label": "Access type",
                                          "config": { "mode": "buttons", "values": ["opportunistic", "reserved"] },
                                          "value_type": "string",
                                          "description": "Choose access type" },
                                        { "id": "id6",
                                          "type": "date",
                                          "label": "Start of service",
                                          "value_type": "string",
                                          "description": "Please choose start date" }])

    checkin_sign_in_as(user)
    visit service_path(offer.service)
    expect(page.body).to have_content("Number of CPU Cores")
    expect(page.body).to have_content("1 - 8")
    expect(page.body).to have_content("Amount of RAM per CPU core")
    expect(page.body).to have_content("1 - 4 GB")
    expect(page.body).to have_content("Local disk")
    expect(page.body).to have_content("10 - 40 GB")
    expect(page.body).to have_content("Number of VM instances")
    expect(page.body).to have_content("10 - 40 GB")
    expect(page.body).to_not have_content("Access type")
    expect(page.body).to_not have_content("Start of service")
  end

  context "as not logged in user" do
    scenario "I need to login to asks service question" do
      service = create(:service)

      visit service_path(service)

      expect(page).to have_content "If you want to ask a question about this service please login"
    end
  end
end


RSpec.feature "Service filtering and sorting" do
  let!(:platform) { create(:platform) }
  let!(:target_group) { create(:target_group) }

  before(:each) do
    platform_2 = create(:platform)
    area = create(:research_area, name: "area 1")
    provider = create(:provider, name: "first provider")
    category_1 = create(:category)

    service = create(:service,
                     title: "AAAA Service",
                     rating: 5.0,
                     target_groups: [target_group],
                     platforms: [platform],
                     categories: [category_1])

    service.providers << provider
    service.research_areas << area

    create(:service, title: "BBBB Service", rating: 3.0, target_groups: [target_group], platforms: [platform_2],
           categories: [category_1])
    create(:service, title: "CCCC Service", rating: 4.0, target_groups: [target_group], platforms: [platform_2],
           categories: [category_1])
    create(:service, title: "DDDD Something 1", rating: 4.1, platforms: [platform_2], categories: [category_1])
    create(:service, title: "DDDD Something 2", rating: 4.0, platforms: [platform_2], categories: [category_1])
    create(:service, title: "DDDD Something 3", rating: 3.9, platforms: [platform_2], categories: [category_1])

    sleep(1)
  end

  scenario "searching in top bar will preserve existing query params", js: true do
    visit services_path(sort: "title")

    fill_in "q", with: "DDDD Something"
    click_on(id: "query-submit")

    expect(page.body.index("DDDD Something 1")).to be < page.body.index("DDDD Something 2")
    expect(page.body.index("DDDD Something 2")).to be < page.body.index("DDDD Something 3")

    expect(page).to have_selector(".media", count: 3)
  end

  scenario "clicking filter button in side bar will preserve existing query params", js: true do
    visit services_path(sort: "title", q: "DDDD Something", utf8: "✓")

    click_on(id: "filter-submit")

    expect(page.body.index("DDDD Something 1")).to be < page.body.index("DDDD Something 2")
    expect(page.body.index("DDDD Something 2")).to be < page.body.index("DDDD Something 3")

    expect(page).to have_selector(".media", count: 3)
  end

  scenario "selecting sorting will set query param and preserve existing ones", js: true do
    visit services_path(q: "DDDD Something", utf8: "✓")

    select "by rate 1-5", from: "sort"

    # For turbolinks to load
    sleep(1)

    expect(page.body.index("DDDD Something 3")).to be < page.body.index("DDDD Something 2")
    expect(page.body.index("DDDD Something 2")).to be < page.body.index("DDDD Something 1")
  end

  scenario "limit number of services per page" do
    create_list(:service, 2)

    visit services_path(per_page: "1")

    expect(page).to have_selector(".media", count: 1)
  end


  scenario "multiselect toggle", js: true do
    visit services_path

    expect(page).to have_selector("input[name='providers[]']:not([style*=\"display: none\"])", count: 5)
    click_on("Show 2 more")
    expect(page).to have_selector("input[name='providers[]']:not([style*=\"display: none\"])", count: 7)
    click_on("Show less")
    expect(page).to have_selector("input[name='providers[]']:not([style*=\"display: none\"])", count: 5)
  end

  scenario "multiselect shows checked element regardless of toggle state", js: true do
    visit services_path

    expect(page).to have_selector("input[name='providers[]']", count: 5)
    click_on("Show 2 more")
    expect(page).to have_selector("input[name='providers[]']", count: 7)
    find(:css, "input[name='providers[]'][value='#{Provider.order(:name).last.id}']").set(true)
    click_on(id: "filter-submit")
    expect(page).to have_selector("input[name='providers[]']", count: 6)
  end

  scenario "multiselect does not show toggle button if everything is shown", js: true do
    visit services_path

    expect(page).to have_selector("input[name='providers[]']", count: 5)
    click_on("Show 2 more")
    find(:css, "input[name='providers[]'][value='#{Provider.joins(:services)
                                                      .order(:name)
                                                      .group("providers.id")
                                                      .order(:name)[-1].id}']").set(true)
    find(:css, "input[name='providers[]'][value='#{Provider.joins(:services)
                                                      .order(:name)
                                                      .group("providers.id")
                                                      .order(:name)[-2].id}']").set(true)
    click_on(id: "filter-submit")

    expect(page).to_not have_selector("#providers > a")
  end

  scenario "toggle button changes number of providers to show", js: true do
    visit services_path
    click_on("Show 2 more")
    find(:css, "input[name='providers[]'][value='#{Provider.order(:name).last.id}']").set(true)
    click_on(id: "filter-submit")

    find("#providers > a", text: "Show 1 more")
  end

  scenario "searching via providers", js: true do
    visit services_path
    find(:css, "input[name='providers[]'][value='#{Provider.order(:name).first.id}']").set(true)
    click_on(id: "filter-submit")

    expect(page).to have_selector(".media", count: 1)
    expect(page).to have_selector("input[name='providers[]']" +
                                      "[value='#{Provider.order(:name).first.id}'][checked='checked']")
  end

  scenario "searching via rating", js: true do
    visit services_path
    select "★★★★★", from: "rating"
    click_on(id: "filter-submit")

    expect(page).to have_selector(".media", count: 1)
  end

  scenario "searching vis research_area" do
    visit services_path
    select ResearchArea.first.name, from: "research_area"
    click_on(id: "filter-submit")

    expect(page).to have_selector(".media", count: 1)
  end

  scenario "searching via target_groups", js: true do
    visit services_path
    find(:css, "input[name='target_groups[]'][value='#{target_group.id}']").set(true)
    click_on(id: "filter-submit")

    expect(page).to have_selector(".media", count: 3)
    expect(page).to have_selector("input[name='target_groups[]'][value='#{target_group.id}'][checked='checked']")
  end

  scenario "searching via platforms", js: true do
    visit services_path
    find(:css, "input[name='related_platforms[]'][value='#{platform.id}']").set(true)
    click_on(id: "filter-submit")

    expect(page).to have_selector(".media", count: 1)
  end

  scenario "page query param should be reset after filtering", js: true do
    create_list(:service, 40)
    visit services_path(page: 3)
    find(:css, "input[name='related_platforms[]'][value='#{platform.id}']").set(true)
    click_on(id: "filter-submit")

    expect(page.current_path).to_not have_content("page=")
    expect(page).to have_selector(".media", count: 1)
  end

  scenario "should have 'All' link in categories with all services count" do
    visit services_path

    expect(page).to have_css("#all-services-link > span", text: Service.all.count)
  end

  scenario "delete all filters" do
    visit services_path

    # set filters
    find(:css, "input[name='target_groups[]'][value='#{target_group.id}']").set(true)
    select "★★★★★", from: "rating"

    click_on(id: "filter-submit")

    expect(page).to have_selector(".media", count: 1)

    # click clear filters
    click_on("Clear all filters")

    expect(page).to have_css(".media", count: 6)
  end

  scenario "searching via location", js: true do
    `pending "add test after implementing location to filtering #{__FILE__}"`
  end
end


RSpec.feature "Service view" do
  scenario "should by default sort services by name, ascending" do
    create(:service, title: "Service c")
    create(:service, title: "Service b")
    create(:service, title: "Service a")

    visit services_path

    expect(page.body.index("Service a")).to be < page.body.index("Service b")
    expect(page.body.index("Service b")).to be < page.body.index("Service c")
  end
end

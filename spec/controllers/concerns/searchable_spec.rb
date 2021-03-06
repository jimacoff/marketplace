# frozen_string_literal: true

require "rails_helper"

class SearchableFakeController < ApplicationController
  include Service::Searchable
end

RSpec.describe SearchableFakeController do
  let!(:platform_1) { create(:platform) }
  let!(:platform_2) { create(:platform) }
  let!(:provider_1) { create(:provider) }
  let!(:provider_2) { create(:provider) }
  let!(:target_group) { create(:target_group) }
  let!(:service_1) do  create(:service,
                              providers: [provider_1],
                              target_groups: [target_group],
                              platforms: [platform_1])
  end
  let!(:service_2) do  create(:service,
                              providers: [provider_2],
                              target_groups: [target_group],
                              platforms: [platform_2])
  end
  let!(:category_1) { create(:category, services: [service_1, service_2]) }
  let!(:category_2) { create(:category, services: [service_2]) }
  let!(:controller) { SearchableFakeController.new }

  context "provider_options" do
    it "should count services depending on the category" do
      expect(controller.send(:provider_options, category_2).size).to eq(1)
      expect(controller.send(:provider_options, category_2).first).to eq([provider_2.name, provider_2.id, 1])
    end

    it "should count all services if no category is specified" do
      expect(controller.send(:provider_options).size).to eq(2)
      expect(controller.send(:provider_options)).to include([provider_2.name, provider_2.id, 1])
    end

  end

  context "target_groups_options" do
    it "should count services depending on the category 2" do
      expect(controller.send(:target_groups_options, category_2).size).to eq(1)
      expect(controller.send(:target_groups_options, category_2).first).to eq([target_group.name, target_group.id, 1])
    end

    it "should count services depending on the category 1" do
      expect(controller.send(:target_groups_options, category_1).size).to eq(1)
      expect(controller.send(:target_groups_options, category_1).first).to eq([target_group.name, target_group.id, 2])
    end

    it "should count all services if no category is specified" do
      expect(controller.send(:target_groups_options).size).to eq(1)
      expect(controller.send(:target_groups_options)).to include([target_group.name, target_group.id, 2])
    end
  end

  context "related_platform_options" do
    it "should count services depending on the category" do
      expect(controller.send(:related_platform_options, category_2).size).to eq(1)
      expect(controller.send(:related_platform_options, category_2)).to include([platform_2.name, platform_2.id, 1])
    end

    it "should count all services if no category is specified" do
      expect(controller.send(:related_platform_options).size).to eq(2)
      expect(controller.send(:related_platform_options)).to include([platform_2.name, platform_2.id, 1])
    end
  end
end

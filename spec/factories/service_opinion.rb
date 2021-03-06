# frozen_string_literal: true

FactoryBot.define do
  factory :service_opinion do
    sequence(:opinion) { |n| "service #{n} opinion" }
    project_item
  end
end

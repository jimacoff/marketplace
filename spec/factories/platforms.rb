# frozen_string_literal: true

FactoryBot.define do
  factory :platform do
    sequence(:name) { |n| "platform #{n}" }
  end
end

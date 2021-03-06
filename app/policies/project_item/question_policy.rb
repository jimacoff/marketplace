# frozen_string_literal: true

class ProjectItem::QuestionPolicy < ApplicationPolicy
  def create?
    record.project_item.active? && record.project_item.user == user
  end

  def permitted_attributes
    [:text]
  end
end

# frozen_string_literal: true

class ServicePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def show?
    true
  end

  def order?
    record.offers_count.positive? && !record.catalog?
  end

  def offers_show?
    record.offers_count > 1
  end
end

# frozen_string_literal: true

module ServiceHelper
  def print_rating_stars(rating)
    result = ""
    # full stars
    for i in 0...rating.floor
      result += content_tag(:i, "", class: "fas fa-star fa-lg")
    end
    # half stars
    if rating % 1 != 0
      result += content_tag(:i, "", class: "fas fa-star-half-alt fa-lg")
    end
    # empty stars
    for i in 0...5 - rating.ceil
      result += content_tag(:i, "", class: "far fa-star fa-lg")
    end
    result.html_safe
  end

  def get_providers_list
    Provider.all
  end

  def any_present?(record, *fields)
    fields.map { |f| record.send(f) }.any? { |v| v.present? }
  end

  def get_terms_and_condition_hint_text(service)
    "You are about to order an #{service.title}. Please accept " \
      "#{link_to service.title, service.terms_of_use_url} to preceed.".html_safe
  end

  def dedicated_for_links(service)
    service.target_groups.map { |target| link_to(target.name, services_path(target_groups: target)) }
  end

  def dedicated_for_text(service)
    service.target_groups.map { |target| target.name }
  end

  def providers(service)
    service.providers.map { |target| link_to(target.name, services_path(providers: target)) }
  end

  def providers_text(service)
    service.providers.map { |target| target.name }
  end
end

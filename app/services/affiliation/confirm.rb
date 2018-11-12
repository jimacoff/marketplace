# frozen_string_literal: true

class Affiliation::Confirm
  attr_reader :error

  def initialize(user, token)
    @token = token
    @user = user
  end

  def call
    @error = nil
    affiliation = Affiliation.find_by_token(@token)

    if !affiliation
      @error = "Affiliation cannot be found"
      false
    elsif affiliation.user != @user
      @error = "Affiliation does not belong to you"
      false
    else
      affiliation.update(status: :active,
                         token: Affiliation.generate_unique_secure_token)
    end
  end
end

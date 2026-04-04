# frozen_string_literal: true

class LocalesController < ApplicationController
  def update
    locale = params[:locale]&.to_sym

    cookies[:locale] = { value: locale, expires: 1.year.from_now } if I18n.available_locales.include?(locale)

    redirect_back_or_to root_path
  end
end

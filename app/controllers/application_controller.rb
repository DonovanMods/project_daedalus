# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include ActionView::Helpers::SanitizeHelper

  before_action :set_locale

  private

  def set_locale
    I18n.locale = locale_from_cookie || locale_from_header || I18n.default_locale
  end

  def locale_from_cookie
    locale = cookies[:locale]&.to_sym
    locale if locale.present? && I18n.available_locales.include?(locale)
  end

  def locale_from_header
    return unless request.env["HTTP_ACCEPT_LANGUAGE"]

    accepted = request.env["HTTP_ACCEPT_LANGUAGE"]
      .scan(/[a-z]{2}(?=-|,|;)/)
      .map(&:to_sym)

    accepted.find { |locale| I18n.available_locales.include?(locale) }
  end
end

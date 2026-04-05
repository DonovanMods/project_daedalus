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
    header = request.env["HTTP_ACCEPT_LANGUAGE"]
    return unless header

    # Parse Accept-Language with q-value weights (e.g. "en-US,en;q=0.9,fr;q=0.8")
    # Filters out q=0 ("not acceptable"), preserves original order as tie-breaker
    accepted = header.split(",").each_with_index.filter_map do |entry, index|
      language_range, *params = entry.strip.split(";")
      locale_code = language_range.to_s[/\A([a-z]{2})(?:-[A-Za-z]{2})?\z/i, 1]
      next unless locale_code

      quality = params.find { |param| param.strip.start_with?("q=") }
      q_value = quality ? quality.strip.delete_prefix("q=").to_f : 1.0
      next unless q_value.positive?

      [locale_code.downcase.to_sym, q_value, index]
    end

    accepted
      .sort_by { |_locale, q_value, index| [-q_value, index] }
      .map { |locale, _q, _i| locale }
      .find { |locale| I18n.available_locales.include?(locale) }
  end
end

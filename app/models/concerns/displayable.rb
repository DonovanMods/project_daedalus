# frozen_string_literal: true

require "net/http"

module Displayable
  extend ActiveSupport::Concern

  def readme
    return @readme if defined?(@readme)

    @readme = readme_url.present? ? fetch_readme : nil
    @readme
  end

  def details
    return readme if readme.present?

    description
  end

  def author_slug
    return "unknown" unless author

    author.parameterize
  end

  def updated_string
    "Last Updated on #{updated_at.strftime("%B %d, %Y")}"
  end

  # Returns a human-readable "time ago" string for the last update
  # e.g. "2 hours ago", "3 days ago", "1 month ago"
  def updated_ago
    return "Unknown" unless updated_at

    seconds = (Time.current - updated_at).to_i
    return "just now" if seconds < 60

    minutes = seconds / 60
    return "#{minutes} #{"minute".pluralize(minutes)} ago" if minutes < 60

    hours = minutes / 60
    return "#{hours} #{"hour".pluralize(hours)} ago" if hours < 24

    days = hours / 24
    return "#{days} #{"day".pluralize(days)} ago" if days < 30

    months = days / 30
    return "#{months} #{"month".pluralize(months)} ago" if months < 12

    years = months / 12
    "#{years} #{"year".pluralize(years)} ago"
  end

  def version_string
    v = []
    v << "v#{version}" if version.present?
    v << compatibility if compatibility.present?

    v.join(" / ")
  end

  private

  def fetch_readme
    # Strip only the leading H1 title line of the README, as it's usually a title
    Net::HTTP.get(raw_uri(readme_url)).sub(/\A#\s+.*\n?/, "").strip
  rescue SocketError, Errno::ECONNREFUSED, Timeout::Error,
         Net::HTTPError, Net::HTTPClientException, URI::InvalidURIError, OpenSSL::SSL::SSLError => e
    Rails.logger.error("Failed to fetch README for '#{name}' from #{readme_url}: #{e.class} - #{e.message}")
    nil
  end
end

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
    author.parameterize
  end

  def updated_string
    "Last Updated on #{updated_at.strftime("%B %d, %Y")}"
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

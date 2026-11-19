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

  def version_string
    v = []
    v << "v#{version}" if version.present?
    v << compatibility if compatibility.present?

    v.join(" / ")
  end

  private

  def fetch_readme
    # Strip only the leading H1 title line of the README, as it's usually a title
    utf8(Net::HTTP.get(raw_uri(readme_url))).sub(/\A#\s+.*\n?/, "").strip
  rescue SocketError, Errno::ECONNREFUSED, Timeout::Error,
         Net::HTTPError, Net::HTTPClientException, URI::InvalidURIError, OpenSSL::SSL::SSLError => e
    Rails.logger.error("Failed to fetch README for '#{name}' from #{readme_url}: #{e.class} - #{e.message}")
    nil
  end

  # Net::HTTP hands the body back as binary (ASCII-8BIT). READMEs are UTF-8, and left as binary the
  # HTML sanitizer reads every byte as Latin-1: an em dash comes out as "â" plus two control characters.
  def utf8(body)
    text = body.dup.force_encoding(Encoding::UTF_8)
    # A byte that is not UTF-8 (a Windows "ANSI" text file, say) is read as Windows-1252 rather than lost.
    text = text.scrub { |bytes| bytes.encode(Encoding::UTF_8, Encoding::WINDOWS_1252, undef: :replace) }
    text.delete_prefix("\u{FEFF}")
  end
end

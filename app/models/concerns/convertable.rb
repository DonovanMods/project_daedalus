# frozen_string_literal: true

module Convertable
  extend ActiveSupport::Concern

  def raw_uri(url)
    uri = URI(url)

    case uri.host
    when /github/
      github(uri)
    else
      uri
    end
  end

  # Convert GitHub URLs to raw.githubusercontent.com URLs
  def github(uri)
    if uri.host.include?("github.com")
      uri.host = "raw.githubusercontent.com"
      uri.path.gsub!(%r{/raw/}, "/")
    end

    uri
  end
end

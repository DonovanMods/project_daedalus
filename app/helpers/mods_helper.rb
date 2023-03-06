# frozen_string_literal: true

module ModsHelper
  def raw_url(url)
    return url unless url&.include?("github.com")

    url.gsub(%r{/blob/}, "/raw/")
  end
end

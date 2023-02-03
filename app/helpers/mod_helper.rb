# frozen_string_literal: true

module ModHelper
  def raw_url(url)
    return url unless url&.include?("github.com")

    url.gsub(%r{/blob/}, "/raw/")
  end
end

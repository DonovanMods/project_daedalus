# frozen_string_literal: true

module ModHelper
  def raw_url(url)
    return url unless url&.include?("github.com")

    # Convert GitHub blob URLs to raw.githubusercontent.com
    # From: https://github.com/user/repo/blob/branch/path/file.ext
    # To:   https://raw.githubusercontent.com/user/repo/branch/path/file.ext
    url.sub(%r{github\.com/([^/]+)/([^/]+)/blob/(.+)}, 'raw.githubusercontent.com/\1/\2/\3')
  end
end

# frozen_string_literal: true

module ModHelper
  def raw_url(url)
    return url unless url&.include?("github.com")

    # Convert GitHub blob URLs to raw.githubusercontent.com
    # From: https://github.com/user/repo/blob/branch/path/file.ext
    # To:   https://raw.githubusercontent.com/user/repo/branch/path/file.ext
    url.sub(%r{github\.com/([^/]+)/([^/]+)/blob/(.+)}, 'raw.githubusercontent.com/\1/\2/\3')
  end

  # Human-readable "time ago" for last update (e.g., "3 days ago")
  def updated_ago(mod_or_tool)
    return "Unknown" unless mod_or_tool.updated_at

    "#{time_ago_in_words(mod_or_tool.updated_at)} ago"
  end

  # Human-readable age since creation (e.g., "about 1 year")
  def mod_age(mod)
    return nil unless mod.created_at

    time_ago_in_words(mod.created_at)
  end
end

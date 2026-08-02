# frozen_string_literal: true

module ModHelper
  DOWNLOAD_BUTTON_CLASSES = {
    pak: "bg-emerald-600 hover:bg-emerald-700 focus:ring-emerald-400",
    zip: "bg-indigo-600 hover:bg-indigo-700 focus:ring-indigo-500"
  }.freeze

  ICARUS_BUTTON_CLASSES = "bg-icarus-500 hover:bg-icarus-600 focus:ring-icarus-400"

  def raw_url(url)
    return url unless url&.include?("github.com")

    # Convert GitHub blob URLs to raw.githubusercontent.com
    # From: https://github.com/user/repo/blob/branch/path/file.ext
    # To:   https://raw.githubusercontent.com/user/repo/branch/path/file.ext
    url.sub(%r{github\.com/([^/]+)/([^/]+)/blob/(.+)}, 'raw.githubusercontent.com/\1/\2/\3')
  end

  # Per-format color classes for download buttons (listing + show page).
  # Exmod-family and unknown types use the default icarus gold.
  def download_button_classes(type)
    DOWNLOAD_BUTTON_CLASSES.fetch(type.to_s.downcase.to_sym, ICARUS_BUTTON_CLASSES)
  end
end

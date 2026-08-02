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

  # The download type the listing button should offer for this mod,
  # honoring an active ?type= filter.
  def effective_download_type(mod)
    mod.download_type_for(params[:type])
  end

  # Header link for a sortable listing column: preserves the active
  # query/type filters, resets pagination, toggles direction on the
  # active column, and marks it with an arrow.
  def sort_link(label, key, current_sort:, current_dir:)
    active = current_sort == key
    arrow, next_dir = sort_state_for(key, active, current_dir)
    link_params = { query: params[:query], type: params[:type], sort: key, dir: next_dir }.compact_blank

    link_to "#{label}#{arrow}", "#{request.path}?#{link_params.to_query}",
            data: { turbo_action: "advance" }, class: "no-underline text-icarus-500"
  end

  private

  def sort_state_for(key, active, current_dir)
    if active
      arrow = current_dir == "asc" ? " ▲" : " ▼"
      next_dir = current_dir == "asc" ? "desc" : "asc"
    else
      arrow = ""
      next_dir = Mod.default_dir_for(key)
    end
    [arrow, next_dir]
  end
end

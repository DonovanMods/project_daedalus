# frozen_string_literal: true

module AnalyticsHelper
  # Computes author-level stats from the full mods list
  def author_stats(mod, all_mods)
    author_mods = all_mods.select { |m| m.author == mod.author }
    file_type_counts = author_mods.flat_map(&:file_types).tally

    {
      total_mods: author_mods.size,
      file_type_counts: file_type_counts,
      newest_mod: author_mods.max_by { |m| m.updated_at || Time.at(0) },
      oldest_mod: author_mods.min_by { |m| m.created_at || Time.current }
    }
  end

  # Returns a freshness label and color class based on days since update
  def freshness_indicator(days)
    return { label: "Unknown", css: "text-slate-400" } if days.nil?

    if days <= 7
      { label: "Fresh", css: "text-emerald-500" }
    elsif days <= 30
      { label: "Recent", css: "text-icarus-500" }
    elsif days <= 90
      { label: "Aging", css: "text-yellow-500" }
    else
      { label: "Stale", css: "text-red-400" }
    end
  end

  # Parses compatibility string (e.g. "w125") into a week number
  def parse_week_number(compatibility)
    return nil if compatibility.blank?

    match = compatibility.match(/w(\d+)/i)
    match ? match[1].to_i : nil
  end
end

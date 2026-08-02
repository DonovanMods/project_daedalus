# frozen_string_literal: true

module Downloadable
  extend ActiveSupport::Concern

  def files?
    files.keys.any?
  end

  def pak?
    files.key?(:pak)
  end

  def zip?
    files.key?(:zip)
  end

  def exmod?
    files.key?(:exmod)
  end

  def exmodz?
    files.key?(:exmodz)
  end

  # Whether this mod offers the given download format.
  # "exmod" covers both exmod and exmodz; unknown types match everything (ALL).
  # rubocop:disable Naming/PredicatePrefix
  def has_download_type?(type)
    case type.to_s.downcase
    when "pak" then pak?
    when "zip" then zip?
    when "exmod" then exmod? || exmodz?
    else true
    end
  end
  # rubocop:enable Naming/PredicatePrefix

  # The download type the listing should offer when a format filter is
  # active: the filtered format itself when this mod provides it,
  # otherwise the normal preferred_type.
  def download_type_for(filter)
    case filter.to_s.downcase
    when "pak" then pak? ? :pak : preferred_type
    when "zip" then zip? ? :zip : preferred_type
    when "exmod" then exmod? || exmodz? ? exmod_type : preferred_type
    else preferred_type
    end
  end

  # Determines which file type is downloaded from the index page
  # Priority: zip > pak > exmodz > exmod
  def preferred_type
    return :zip if zip?
    return :pak if pak?
    return :exmodz if exmodz?
    return :exmod if exmod?

    nil
  end

  # Determines which file types can be downloaded from the show page,
  # rendered in the same priority order as preferred_type
  def download_types
    %i[zip pak exmodz exmod] & file_types.map(&:to_sym)
  end

  def file_types
    files.keys
  end

  def urls
    files.values
  end

  def get_url(type)
    files[type.to_sym]
  end

  def get_name(type)
    filename(files[type.to_sym])
  end

  def types_string
    file_types.map(&:upcase).sort.join(" / ")
  end

  private

  def filename(url)
    return if url.blank?

    url.split("?").first.split("/").last
  end

  def exmod_type
    files.key?(:exmodz) ? :exmodz : :exmod
  end
end

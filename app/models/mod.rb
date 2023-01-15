# frozen_string_literal: true

require "net/http"

class Mod
  include ActiveModel::Model

  SORTKEYS = %w[name author].freeze
  ATTRIBUTES = %i[id name author version compatibility description long_description file_type url image_url readme_url created_at updated_at].freeze

  ATTRIBUTES.each { |attr| attr_accessor attr }

  def details
    return Net::HTTP.get(URI(readme_url)).gsub(/^#\s+.*$/, "").strip if readme_url.present?

    long_description if long_description.present?

    description
  end

  def filename
    url.split("/").last
  end

  def updated_string
    "Last Updated on #{updated_at.strftime('%B %d, %Y')}"
  end

  def version_string
    "v#{version} (#{compatibility})"
  end
end

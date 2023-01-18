# frozen_string_literal: true

require "net/http"

class Mod
  include ActiveModel::Model

  SORTKEYS = %w[author name].freeze
  ATTRIBUTES = %i[id name author version compatibility description long_description file_type url image_url readme_url created_at updated_at].freeze

  ATTRIBUTES.each { |attr| attr_accessor attr }

  def readme
    @readme ||= Net::HTTP.get(URI(readme_url)).gsub(/^#\s+.*$/, "").strip if readme_url.present?
  end

  def details
    return readme if readme.present?

    return long_description if long_description.present?

    description
  end

  def filename
    url.split("/").last
  end

  def slug
    name.parameterize
  end

  def updated_string
    "Last Updated on #{updated_at.strftime('%B %d, %Y')}"
  end

  def version_string
    "v#{version} (#{compatibility})"
  end
end

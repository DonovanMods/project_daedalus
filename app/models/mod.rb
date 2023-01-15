# frozen_string_literal: true

class Mod
  include ActiveModel::Model

  SORTKEYS = %w[name author].freeze
  ATTRIBUTES = %i[id name author version compatibility description long_description file_type url image_url created_at updated_at].freeze

  ATTRIBUTES.each { |attr| attr_accessor attr }

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

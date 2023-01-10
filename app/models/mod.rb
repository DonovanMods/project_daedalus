# frozen_string_literal: true

class Mod
  include ActiveModel::Model

  SORTKEYS = %w[name author].freeze

  %i[id name author version compatibility description long_description file_type url image_url created_at updated_at].each do |attr|
    attr_accessor attr
  end

  def filename
    url.split("/").last
  end

  def updated_string
    "Last Updated on #{updated_at.strftime('%B %d, %Y')}"
  end

  def version_string
    "v#{version}"
  end
end

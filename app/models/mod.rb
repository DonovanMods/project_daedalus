# frozen_string_literal: true

require "net/http"

class Mod
  include ActiveModel::Model
  include Convertable
  include Firestorable

  SORTKEYS = %w[author name].freeze
  ATTRIBUTES = %i[id name author version compatibility description long_description file_type url image_url readme_url created_at updated_at].freeze

  ATTRIBUTES.each { |attr| attr_accessor attr }

  def self.all
    @all ||= firestore.col("mods").get.filter_map do |mod|
      new(
        id: mod.document_id,
        name: mod.data[:name],
        author: mod.data[:author],
        description: mod.data[:description],
        long_description: mod.data[:long_description],
        version: mod.data[:version],
        compatibility: mod.data[:compatibility],
        file_type: mod.data[:fileType],
        url: mod.data[:fileURL],
        image_url: mod.data[:imageURL],
        readme_url: mod.data[:readmeURL],
        created_at: mod.create_time,
        updated_at: mod.update_time
      )
    end.sort_by(&:name)
  end

  def readme
    # We stip out the first # line of the README, as it's usually a title
    @readme ||= Net::HTTP.get(raw_uri(readme_url)).gsub(/^#\s+.*$/, "").strip if readme_url.present?
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
    v = []
    v << "v#{version}" if version.present?
    v << compatibility if compatibility.present?

    v.join(" / ")
  end
end

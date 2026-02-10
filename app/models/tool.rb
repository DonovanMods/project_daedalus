# frozen_string_literal: true

class Tool
  include ActiveModel::Model
  include Convertable
  include Displayable
  include Firestorable

  SORTKEYS = %w[author name].freeze
  ATTRIBUTES = %i[id name author version compatibility description file_type url image_url readme_url created_at
                  updated_at].freeze

  ATTRIBUTES.each { |attr| attr_accessor attr }

  def self.all
    Rails.cache.fetch("firestore/tools", expires_in: 5.minutes) do
      fetch_all
    end
  end

  def self.fetch_all # :nodoc:
    firestore.col("tools").get.filter_map do |tool|
      new(
        id: tool.document_id,
        name: tool.data[:name],
        author: tool.data[:author],
        description: tool.data[:description],
        version: tool.data[:version],
        compatibility: tool.data[:compatibility],
        file_type: tool.data[:fileType],
        url: tool.data[:fileURL],
        image_url: tool.data[:imageURL],
        readme_url: tool.data[:readmeURL],
        created_at: tool.create_time,
        updated_at: tool.update_time
      )
    end.sort_by(&:name)
  end
  private_class_method :fetch_all

  def self.expire_cache
    Rails.cache.delete("firestore/tools")
  end

  def filename
    url.split("/").last
  end

  def name_slug
    name.parameterize
  end

  def slug
    "#{author_slug}-#{name_slug}"
  end
end

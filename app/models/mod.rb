# frozen_string_literal: true

class Mod
  include ActiveModel::Model
  include Convertable
  include Displayable
  include Downloadable
  include Firestorable

  SORTKEYS = %w[author name].freeze
  ATTRIBUTES = %i[author compatibility description files id image_url metadata name readme_url timestamps version
                  created_at updated_at].freeze

  ATTRIBUTES.each { |attr| attr_accessor attr }

  def self.all
    Rails.cache.fetch("firestore/mods", expires_in: 5.minutes) do
      fetch_all
    end
  end

  def self.fetch_all # :nodoc:
    mods = firestore.col("mods").get.filter_map do |mod|
      new(
        author: mod.data[:author],
        compatibility: mod.data[:compatibility],
        description: mod.data[:description],
        files: mod.data[:files] || {},
        id: mod.document_id,
        image_url: mod.data[:imageURL],
        metadata: mod.data[:meta],
        name: mod.data[:name],
        readme_url: mod.data[:readmeURL],
        version: mod.data[:version],
        created_at: mod.create_time,
        updated_at: mod.update_time
      )
    end

    mods.uniq { |mod| [mod.name.downcase, mod.author_slug] }.sort_by(&:name)
  end
  private_class_method :fetch_all

  def self.expire_cache
    Rails.cache.delete("firestore/mods")
  end

  def slug
    name.parameterize
  end
end

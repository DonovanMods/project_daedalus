# frozen_string_literal: true

class Mod
  include ActiveModel::Model
  include Convertable
  include Displayable
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

  def self.fetch_all
    firestore.col("mods").get.filter_map do |mod|
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
    end.sort_by(&:name)
  end

  def self.expire_cache
    Rails.cache.delete("firestore/mods")
  end

  def files?
    files.keys.any?
  end

  def pak?
    files.key?(:pak)
  end

  def zip?
    files.key?(:zip)
  end

  def exmodz?
    files.key?(:exmodz)
  end

  # Determines which file types can be downloaded from the index page
  def preferred_type
    return :pak if pak?

    :zip if zip?
  end

  # Determines which file types can be downloaded from the show page
  def download_types
    file_types.map(&:to_sym) & %i[pak zip exmodz]
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

  def slug
    name.parameterize
  end

  private

  def filename(url)
    return unless url

    URI(url).path.split("/").last
  end

  def exmod_type
    files.key?(:exmodz) ? :exmodz : :exmod
  end
end

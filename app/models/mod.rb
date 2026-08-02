# frozen_string_literal: true

class Mod
  include ActiveModel::Model
  include Convertable
  include Displayable
  include Downloadable
  include Firestorable

  SORTKEYS = %w[updated name download author].freeze
  SORT_DEFAULT_DIRS = { "updated" => "desc" }.freeze
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

  def self.default_dir_for(key)
    SORT_DEFAULT_DIRS.fetch(key, "asc")
  end

  # Sorts a listing of mods for the index table. `key` must be in SORTKEYS
  # (unknown keys return the input untouched). Mods without updated_at sort
  # last regardless of direction; download sorts by the label the button
  # shows under the active type filter.
  def self.sort_mods(mods, key:, dir:, type_filter: nil)
    return mods unless SORTKEYS.include?(key)

    if key == "updated"
      dated, undated = mods.partition { |mod| mod.updated_at.present? }
      sorted = dated.sort_by(&:updated_at)
      sorted.reverse! if dir == "desc"
      sorted + undated
    else
      sorted = mods.sort_by { |mod| sort_key_for(mod, key, type_filter) }
      dir == "desc" ? sorted.reverse : sorted
    end
  end

  def self.sort_key_for(mod, key, type_filter)
    case key
    when "name" then [mod.name.to_s.downcase]
    when "author" then [mod.author.to_s.downcase, mod.name.to_s.downcase]
    when "download" then [mod.download_type_for(type_filter).to_s, mod.name.to_s.downcase]
    end
  end
  private_class_method :sort_key_for

  def slug
    name.parameterize
  end
end

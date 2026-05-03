# frozen_string_literal: true

# Represents a mod synced from the Nexus Mods API into the `nexus_mods`
# Firestore collection.
#
# Exposes the same public interface as Mod where it overlaps, so the
# existing _mod.html.erb partial can render either type. The differences:
#
#   - preferred_type returns :nexus (no direct download link)
#   - get_url(:nexus) returns the Nexus mod page URL
#   - nexus_source? returns true (Mod returns false)
class NexusMod
  include ActiveModel::Model
  include Displayable
  include Firestorable

  COLLECTION = "nexus_mods"

  ATTRIBUTES = %i[author description downloads endorsements id image_url mod_page_url
                  name nexus_id summary updated_time uploaded_time version
                  created_at updated_at].freeze

  ATTRIBUTES.each { |attr| attr_accessor attr }

  def self.all
    Rails.cache.fetch("firestore/nexus_mods", expires_in: 5.minutes) do
      fetch_all
    end
  end

  def self.fetch_all # :nodoc:
    firestore.col(COLLECTION).get.filter_map do |doc|
      new(
        author:        doc.data[:author],
        description:   doc.data[:description].presence || doc.data[:summary].presence || "",
        downloads:     doc.data[:downloads],
        endorsements:  doc.data[:endorsements],
        id:            doc.document_id,
        image_url:     doc.data[:image_url],
        mod_page_url:  doc.data[:mod_page_url],
        name:          doc.data[:name],
        nexus_id:      doc.data[:nexus_id],
        summary:       doc.data[:summary],
        updated_time:  doc.data[:updated_time],
        uploaded_time: doc.data[:uploaded_time],
        version:       doc.data[:version],
        created_at:    doc.create_time,
        updated_at:    doc.update_time
      )
    end.sort_by { |m| m.name.to_s }
  end
  private_class_method :fetch_all

  def self.expire_cache
    Rails.cache.delete("firestore/nexus_mods")
  end

  # --- Mod-compatible interface for the _mod.html.erb partial ---

  def preferred_type
    :nexus
  end

  def get_url(_type)
    mod_page_url
  end

  def get_name(_type)
    name
  end

  def nexus_source?
    true
  end

  # Render through the existing mods/_mod partial. Without this, Rails
  # collection rendering would look for nexus_mods/_nexus_mod and crash.
  def to_partial_path
    "mods/mod"
  end

  def slug
    name.to_s.parameterize
  end

  # Nexus API doesn't expose Icarus week-compatibility metadata.
  def compatibility
    nil
  end

  # Nexus mods have summaries and descriptions in the API response;
  # we don't fetch a separate README.
  def readme
    nil
  end
end

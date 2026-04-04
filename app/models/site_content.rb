# frozen_string_literal: true

# SiteContent stores editable page content in Firestore.
# Each page is a document in the "site_content" collection.
#
# Example Firestore document for the info page:
#   site_content/info_page => { sections: [...], updated_at: ... }
class SiteContent
  include Firestorable

  COLLECTION = "site_content"
  CACHE_TTL = 2.minutes

  Section = Struct.new(:title, :description, :link_text, :link_url, keyword_init: true)

  attr_reader :page_id, :sections, :updated_at

  def initialize(page_id:, sections: [], updated_at: nil)
    @page_id = page_id
    @sections = sections.map { |s| s.is_a?(Section) ? s : Section.new(**s.symbolize_keys) }
    @updated_at = updated_at
  end

  # Fetch content for a page, with caching
  def self.find(page_id)
    Rails.cache.fetch("site_content/#{page_id}", expires_in: CACHE_TTL) do
      fetch_from_firestore(page_id)
    end
  end

  # Fetch directly from Firestore (bypasses cache)
  def self.fetch_from_firestore(page_id)
    doc = firestore.doc("#{COLLECTION}/#{page_id}").get
    return nil unless doc.exists?

    new(
      page_id: page_id,
      sections: (doc[:sections] || []).map { |s| s.transform_keys(&:to_sym) },
      updated_at: doc[:updated_at]
    )
  end

  # Save content to Firestore and bust cache
  def self.save!(page_id, sections)
    data = {
      sections: sections.map(&:to_h),
      updated_at: Time.current.utc
    }

    firestore.doc("#{COLLECTION}/#{page_id}").set(data)
    Rails.cache.delete("site_content/#{page_id}")

    new(page_id: page_id, sections: sections, updated_at: data[:updated_at])
  end

  # Default info page content (used as fallback and for seeding)
  def self.default_info_sections
    [
      Section.new(
        title: "The Icarus Modding Discord Server",
        description: "This is the unofficial modding Discord server for Icarus. It's a great place to get help with modding, ask questions, and meet other modders.",
        link_text: "Join our Discord",
        link_url: "https://discord.gg/linkarus-icarus-modding-936621749733302292"
      ),
      Section.new(
        title: "The Icarus Modding Upvote Page",
        description: "This is a page where you can upvote or add new mods you'd like to see for Icarus. It's a great way to let us know what you want to see in the future.",
        link_text: "Modding Upvote Page",
        link_url: "https://feedback.projectdaedalus.app/"
      )
    ]
  end
end

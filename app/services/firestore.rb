# frozen_string_literal: true

require "google/cloud/firestore"

# This is a service object that fetches mods from Firestore.
class Firestore
  FILTERED_FILE_TYPES = %w[exmod].freeze

  def initialize
    @client = Google::Cloud::Firestore.new(credentials: Rails.application.credentials.firebase_keyfile.to_h)
  end

  def mods
    @mods ||= @client.col("mods").get.filter_map do |mod|
      next if FILTERED_FILE_TYPES.include?(mod.data[:fileType].to_s.downcase.strip)

      Mod.new(
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
end

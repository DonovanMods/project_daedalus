# frozen_string_literal: true

require "google/cloud/firestore"

# This is a service object that fetches mods/tools from Firestore.
class Firestore
  def initialize
    @client = Google::Cloud::Firestore.new(credentials: Rails.application.credentials.firebase_keyfile.to_h)
  end

  def mods
    @mods ||= @client.col("mods").get.filter_map do |mod|
      # skip exmods
      next if mod.data[:fileType].match?(/exmodz?/i)

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

  def tools
    @tools ||= @client.col("tools").get.filter_map do |tool|
      Tool.new(
        id: tool.document_id,
        name: tool.data[:name],
        author: tool.data[:author],
        description: tool.data[:description],
        long_description: tool.data[:long_description],
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
end

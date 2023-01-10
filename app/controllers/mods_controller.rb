# frozen_string_literal: true

require "google/cloud/firestore"
require "net/http"
require "uri"
require "json"

class ModsController < ApplicationController
  def index
    @mods = fetch_mods.sort_by(&:name)

    return unless Mod::SORTKEYS.include?(params[:sort])

    @mods = @mods.sort_by { |mod| [mod.send(params[:sort]), mod.name] }
  end

  def show
    @mod = fetch_mods.find { |mod| mod.id == params[:id] }
  end

  private

  def client
    @client ||= Google::Cloud::Firestore.new(credentials: Rails.application.credentials.firebase_keyfile.to_h)
  end

  def fetch_mods
    return @mods if @mods

    client.col("mods").get.map do |mod|
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
        created_at: mod.create_time,
        updated_at: mod.update_time
      )
    end
  end
end

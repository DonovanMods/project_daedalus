# frozen_string_literal: true

module Api
  class ModsController < ApplicationController
    skip_forgery_protection

    # GET /api/mods.json
    # Returns a lightweight JSON feed of all mods for external consumers
    # (e.g. Discord bots, RSS readers, CI pipelines).
    def index
      mods = Mod.all

      render json: {
        updated_at: Time.current.iso8601,
        count: mods.size,
        mods: mods.map { |mod| serialize_mod(mod) }
      }
    end

    private

    def serialize_mod(mod)
      {
        id: mod.id,
        name: mod.name,
        author: mod.author,
        version: mod.version,
        compatibility: mod.compatibility,
        description: mod.description,
        image_url: mod.image_url,
        file_types: mod.file_types.map(&:to_s),
        created_at: mod.created_at&.iso8601,
        updated_at: mod.updated_at&.iso8601,
        url: "https://projectdaedalus.app/mods/#{mod.author_slug}/#{mod.slug}"
      }
    end
  end
end

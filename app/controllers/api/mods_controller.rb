# frozen_string_literal: true

module Api
  class ModsController < ApplicationController
    skip_forgery_protection

    # Cache the JSON response to reduce Firestore reads and limit abuse.
    # External consumers should respect Cache-Control / ETag headers.
    CACHE_TTL = 2.minutes

    # GET /api/mods.json
    # Returns a lightweight JSON feed of all mods for external consumers
    # (e.g. Discord bots, RSS readers, CI pipelines).
    def index
      response.headers["Access-Control-Allow-Origin"] = "*"
      response.headers["Access-Control-Allow-Methods"] = "GET"
      response.headers["X-Content-Type-Options"] = "nosniff"

      json = Rails.cache.fetch("api/mods.json", expires_in: CACHE_TTL) do
        mods = Mod.all
        {
          updated_at: Time.current.iso8601,
          count: mods.size,
          mods: mods.map { |mod| serialize_mod(mod) }
        }.to_json
      end

      expires_in CACHE_TTL, public: true
      render json: json
    end

    private

    MAX_DESCRIPTION_LENGTH = 500

    def serialize_mod(mod)
      {
        id: mod.id,
        name: mod.name,
        author: mod.author,
        version: mod.version,
        compatibility: mod.compatibility,
        description: truncate_text(mod.description, MAX_DESCRIPTION_LENGTH),
        image_url: mod.image_url,
        file_types: mod.file_types.map(&:to_s),
        created_at: mod.created_at&.iso8601,
        updated_at: mod.updated_at&.iso8601,
        url: mod_url(mod)
      }
    end

    def mod_url(mod)
      Rails.application.routes.url_helpers.mod_detail_url(
        author: mod.author_slug,
        slug: mod.slug,
        host: request.host,
        protocol: request.protocol
      )
    end

    def truncate_text(text, max_length)
      return "" if text.blank?
      return text if text.length <= max_length

      "#{text[0, max_length - 1]}…"
    end
  end
end

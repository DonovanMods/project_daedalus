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
    rescue StandardError => e
      Rails.logger.error("API mods#index failed: #{e.class} - #{e.message}")
      render json: { error: "Service temporarily unavailable" }, status: :service_unavailable
    end

    private

    MAX_DESCRIPTION_LENGTH = 500
    SITE_HOST = "projectdaedalus.app"

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
        preferred_download: preferred_download(mod),
        created_at: mod.created_at&.iso8601,
        updated_at: mod.updated_at&.iso8601,
        url: mod_url(mod)
      }
    end

    # Returns the primary download URL and format for the mod, if available.
    def preferred_download(mod)
      type = mod.preferred_type
      return nil unless type

      url = mod.get_url(type)
      return nil if url.blank?

      { type: type.to_s, url: url }
    end

    # Use a fixed host so cached responses always contain the production URL,
    # regardless of which host/proxy the first request came through.
    def mod_url(mod)
      Rails.application.routes.url_helpers.mod_detail_url(
        author: mod.author_slug,
        slug: mod.slug,
        host: SITE_HOST,
        protocol: "https"
      )
    end

    def truncate_text(text, max_length)
      return "" if text.blank?
      return text if text.length <= max_length

      "#{text[0, max_length - 1]}…"
    end
  end
end

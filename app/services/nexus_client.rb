# frozen_string_literal: true

require "net/http"
require "json"

# Thin wrapper around the Nexus Mods public API.
# Docs: https://app.swaggerhub.com/apis-docs/NexusMods/nexus-mods_public_api_params_in_form_data
#
# Requires Rails.application.credentials.nexus_api_key (or NEXUS_API_KEY env var)
# to be set. A key can be generated from:
#   https://www.nexusmods.com/users/myaccount?tab=api+access
class NexusClient
  HOST = "api.nexusmods.com"
  GAME = "icarus"
  TIMEOUT = 10

  class Error < StandardError; end
  class NotFound < Error; end
  class RateLimited < Error; end
  class Unauthorized < Error; end

  def initialize(api_key: nil)
    @api_key = api_key || resolve_api_key
    raise Error, "Nexus API key is missing" if @api_key.blank?
  end

  # Latest 10 mods added for the game.
  def latest_added
    get("/v1/games/#{GAME}/mods/latest_added.json")
  end

  # Latest 10 mods updated for the game.
  def latest_updated
    get("/v1/games/#{GAME}/mods/latest_updated.json")
  end

  # Top 10 trending mods for the game.
  def trending
    get("/v1/games/#{GAME}/mods/trending.json")
  end

  # Full details for a specific mod.
  # Raises NotFound if the mod doesn't exist or has been hidden.
  def mod(mod_id)
    get("/v1/games/#{GAME}/mods/#{mod_id}.json")
  end

  private

  def resolve_api_key
    creds = Rails.application.credentials
    from_creds = creds.respond_to?(:nexus_api_key) ? creds.nexus_api_key : nil
    from_creds.presence || ENV["NEXUS_API_KEY"]
  end

  def get(path)
    uri = URI::HTTPS.build(host: HOST, path: path)
    req = Net::HTTP::Get.new(uri)
    req["apikey"] = @api_key
    req["Accept"] = "application/json"
    req["Application-Name"] = "ProjectDaedalus"
    req["Application-Version"] = "1.0"

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true,
                          open_timeout: TIMEOUT, read_timeout: TIMEOUT) do |http|
      http.request(req)
    end

    case res
    when Net::HTTPSuccess         then JSON.parse(res.body)
    when Net::HTTPNotFound        then raise NotFound, "Nexus mod not found at #{path}"
    when Net::HTTPTooManyRequests then raise RateLimited, "Nexus API rate limit hit (429)"
    when Net::HTTPUnauthorized,
         Net::HTTPForbidden       then raise Unauthorized, "Nexus API auth failed (#{res.code})"
    else                               raise Error, "Nexus API #{res.code}: #{res.body}"
    end
  end
end

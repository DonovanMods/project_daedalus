# frozen_string_literal: true

# Pulls mod metadata from the Nexus Mods API and upserts each mod
# into the `nexus_mods` Firestore collection.
#
# Three modes:
#   - sync (steady state): fetches latest_added / latest_updated / trending
#     and refetches each returned mod for fresh details. ~33 requests/run.
#
#   - bootstrap(range): walks a contiguous range of Nexus mod IDs.
#     Used once to seed the collection, since the Nexus API has no
#     "list all mods" endpoint.
#
#   - refresh_all: refetches every mod ID currently in Firestore.
#     One API call per mod — call sparingly (e.g. weekly).
#
# Rate limit notes:
#   Nexus free tier allows 2,500 requests/day, 5,000/hour. The default
#   `sync` mode comfortably fits with multiple runs per day.
class NexusSync
  COLLECTION = "nexus_mods"

  def initialize(client: NexusClient.new, logger: Rails.logger)
    @client = client
    @logger = logger
  end

  # Steady-state sync. Cheap (~33 API calls) and safe to run every few hours.
  def sync
    ids = discover_active_ids
    @logger.info("[NexusSync] sync: refreshing #{ids.size} active mod(s)")

    upsert_each(ids)
  end

  # Walk a range of mod IDs sequentially. Used for initial seeding.
  # Sleeps briefly between requests to be polite to the API.
  def bootstrap(range)
    @logger.info("[NexusSync] bootstrap: walking IDs #{range.first}..#{range.last}")

    upserted = 0
    range.each do |id|
      data = safe_fetch(id)
      next unless data

      upsert(data)
      upserted += 1
      sleep 0.5
    end
    upserted
  end

  # Refetch every mod we already know about. Use sparingly.
  def refresh_all
    ids = NexusMod.firestore.col(COLLECTION).get.map { |doc| doc.document_id.to_i }
    @logger.info("[NexusSync] refresh_all: refreshing #{ids.size} known mod(s)")

    upsert_each(ids)
  end

  private

  def discover_active_ids
    [@client.latest_added, @client.latest_updated, @client.trending]
      .flatten
      .filter_map { |m| m["mod_id"] }
      .uniq
  rescue NexusClient::Error => e
    @logger.warn("[NexusSync] discovery failed: #{e.message}")
    []
  end

  def upsert_each(ids)
    upserted = 0
    ids.each do |id|
      data = safe_fetch(id)
      next unless data

      upsert(data)
      upserted += 1
    end
    upserted
  end

  def safe_fetch(id)
    @client.mod(id)
  rescue NexusClient::NotFound
    nil
  rescue NexusClient::Error => e
    @logger.warn("[NexusSync] mod #{id} fetch failed: #{e.message}")
    nil
  end

  def upsert(data)
    return unless data["available"]

    NexusMod.firestore.col(COLLECTION).doc(data["mod_id"].to_s).set(
      nexus_id:      data["mod_id"],
      name:          data["name"],
      author:        data["author"].presence || data["uploaded_by"],
      summary:       data["summary"],
      description:   data["description"],
      version:       data["version"],
      image_url:     data["picture_url"],
      mod_page_url:  "https://www.nexusmods.com/icarus/mods/#{data["mod_id"]}",
      endorsements:  data["endorsement_count"],
      downloads:     data["mod_downloads"],
      uploaded_time: data["uploaded_time"],
      updated_time:  data["updated_time"],
      synced_at:     Time.now.utc
    )
  end
end

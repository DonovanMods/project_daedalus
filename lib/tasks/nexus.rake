# frozen_string_literal: true

namespace :nexus do
  desc <<~DESC
    Sync Icarus mods from the Nexus Mods API to the `nexus_mods` Firestore
    collection. Discovers recently-added/updated/trending mods (~33 API calls).
    Safe to run on a frequent cron schedule.

    Crontab example (every 4 hours, runs from Donovan's machine):
      0 */4 * * * cd /path/to/project_daedalus && /path/to/bundle exec rake nexus:sync >> log/nexus.log 2>&1
  DESC
  task sync: :environment do
    count = NexusSync.new.sync
    puts "Nexus sync complete: #{count} mod(s) upserted"
  end

  desc <<~DESC
    Bootstrap the `nexus_mods` collection by walking a contiguous range of
    Nexus mod IDs. Use this once to seed the collection — the Nexus API has
    no "list all mods" endpoint, so initial population requires sequential
    enumeration. Sleeps 0.5s between requests.

    Usage:
      RANGE=1..1000 bin/rails nexus:bootstrap
  DESC
  task bootstrap: :environment do
    raise "Set RANGE=first..last (e.g. RANGE=1..1000)" if ENV["RANGE"].blank?

    first, last = ENV["RANGE"].split("..").map(&:to_i)
    raise "Invalid RANGE format. Expected 'first..last'." unless first && last && first <= last

    count = NexusSync.new.bootstrap(first..last)
    puts "Nexus bootstrap complete: #{count} mod(s) upserted from range #{first}..#{last}"
  end

  desc <<~DESC
    Refresh every Nexus mod currently stored in Firestore. Uses one API call
    per mod, so runs against the daily rate limit. Recommended cadence:
    weekly or less. Mostly useful for refreshing endorsement counts and
    download stats, which the cheap `sync` task only touches when a mod
    appears in latest_updated/trending.
  DESC
  task refresh_all: :environment do
    count = NexusSync.new.refresh_all
    puts "Nexus refresh_all complete: #{count} mod(s) upserted"
  end
end

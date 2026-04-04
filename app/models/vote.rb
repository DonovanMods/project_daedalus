# frozen_string_literal: true

class Vote
  include Firestorable

  COLLECTION = "mod_votes"
  RATE_LIMIT_WINDOW = 1.minute
  RATE_LIMIT_MAX = 10 # Max votes per fingerprint per window

  # Check if this fingerprint has already voted for this mod
  def self.exists?(mod_id, fingerprint)
    doc_id = "#{mod_id}_#{fingerprint}"
    firestore.doc("#{COLLECTION}/#{doc_id}").get.exists?
  end

  # Record a vote for a mod
  def self.cast!(mod_id, fingerprint)
    doc_id = "#{mod_id}_#{fingerprint}"

    # Store the vote record for dedup
    firestore.doc("#{COLLECTION}/#{doc_id}").set(
      mod_id: mod_id,
      fingerprint: fingerprint,
      created_at: Time.current.utc
    )

    # Increment the vote count on the mod's vote counter doc
    counter_ref = firestore.doc("mod_vote_counts/#{mod_id}")
    counter = counter_ref.get

    if counter.exists?
      counter_ref.update(count: counter[:count].to_i + 1)
    else
      counter_ref.set(count: 1)
    end
  end

  # Remove a vote (unvote)
  def self.remove!(mod_id, fingerprint)
    doc_id = "#{mod_id}_#{fingerprint}"
    doc_ref = firestore.doc("#{COLLECTION}/#{doc_id}")

    return false unless doc_ref.get.exists?

    doc_ref.delete

    # Decrement the vote count
    counter_ref = firestore.doc("mod_vote_counts/#{mod_id}")
    counter = counter_ref.get

    if counter.exists? && counter[:count].to_i.positive?
      counter_ref.update(count: counter[:count].to_i - 1)
    end

    true
  end

  # Get vote count for a mod
  def self.count_for(mod_id)
    counter = firestore.doc("mod_vote_counts/#{mod_id}").get
    counter.exists? ? counter[:count].to_i : 0
  end

  # Get vote counts for multiple mods at once
  def self.counts_for(mod_ids)
    counts = {}
    mod_ids.each { |id| counts[id] = 0 }

    mod_ids.each do |id|
      counter = firestore.doc("mod_vote_counts/#{id}").get
      counts[id] = counter[:count].to_i if counter.exists?
    end

    counts
  end

  # Rate limiting: check if fingerprint has voted too many times recently
  def self.rate_limited?(fingerprint)
    cutoff = RATE_LIMIT_WINDOW.ago.utc
    recent = firestore.col(COLLECTION)
      .where(:fingerprint, :==, fingerprint)
      .where(:created_at, :>=, cutoff)
      .get

    recent.count >= RATE_LIMIT_MAX
  end
end

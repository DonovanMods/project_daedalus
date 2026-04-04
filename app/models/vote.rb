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

  # Record a vote for a mod using atomic increment to prevent race conditions
  def self.cast!(mod_id, fingerprint)
    doc_id = "#{mod_id}_#{fingerprint}"

    # Store the vote record for dedup
    firestore.doc("#{COLLECTION}/#{doc_id}").set(
      mod_id: mod_id,
      fingerprint: fingerprint,
      created_at: Time.current.utc
    )

    # Atomically increment the vote count using Firestore FieldValue
    counter_ref = firestore.doc("mod_vote_counts/#{mod_id}")
    counter_ref.set(
      { count: Google::Cloud::Firestore::FieldValue.increment(1) },
      merge: true
    )
  end

  # Remove a vote (unvote) using atomic decrement
  def self.remove!(mod_id, fingerprint)
    doc_id = "#{mod_id}_#{fingerprint}"
    doc_ref = firestore.doc("#{COLLECTION}/#{doc_id}")

    return false unless doc_ref.get.exists?

    doc_ref.delete

    # Atomically decrement the vote count
    counter_ref = firestore.doc("mod_vote_counts/#{mod_id}")
    counter_ref.set(
      { count: Google::Cloud::Firestore::FieldValue.increment(-1) },
      merge: true
    )

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

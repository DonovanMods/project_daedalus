# frozen_string_literal: true

require "rails_helper"

RSpec.describe Vote do
  let(:firestore) { instance_double(Google::Cloud::Firestore::Client) }
  let(:collection) { instance_double(Google::Cloud::Firestore::CollectionReference) }
  let(:mod_id) { "test-mod-123" }
  let(:fingerprint) { "abc123fingerprint" }
  let(:doc_id) { "#{mod_id}_#{fingerprint}" }

  before do
    allow(described_class).to receive(:firestore).and_return(firestore)
  end

  describe ".exists?" do
    it "returns true when vote document exists" do
      doc = instance_double(Google::Cloud::Firestore::DocumentSnapshot, exists?: true)
      doc_ref = instance_double(Google::Cloud::Firestore::DocumentReference, get: doc)
      allow(firestore).to receive(:doc).with("mod_votes/#{doc_id}").and_return(doc_ref)

      expect(described_class.exists?(mod_id, fingerprint)).to be true
    end

    it "returns false when vote document does not exist" do
      doc = instance_double(Google::Cloud::Firestore::DocumentSnapshot, exists?: false)
      doc_ref = instance_double(Google::Cloud::Firestore::DocumentReference, get: doc)
      allow(firestore).to receive(:doc).with("mod_votes/#{doc_id}").and_return(doc_ref)

      expect(described_class.exists?(mod_id, fingerprint)).to be false
    end
  end

  describe ".cast!" do
    it "creates a vote record and atomically increments counter" do
      vote_ref = instance_double(Google::Cloud::Firestore::DocumentReference)
      allow(firestore).to receive(:doc).with("mod_votes/#{doc_id}").and_return(vote_ref)
      allow(vote_ref).to receive(:set)

      counter_ref = instance_double(Google::Cloud::Firestore::DocumentReference)
      allow(firestore).to receive(:doc).with("mod_vote_counts/#{mod_id}").and_return(counter_ref)
      allow(counter_ref).to receive(:set)

      described_class.cast!(mod_id, fingerprint)

      expect(vote_ref).to have_received(:set).with(hash_including(mod_id: mod_id, fingerprint: fingerprint))
      expect(counter_ref).to have_received(:set).with(
        { count: an_instance_of(Google::Cloud::Firestore::FieldValue) },
        merge: true
      )
    end
  end

  describe ".remove!" do
    it "deletes vote and atomically decrements counter when vote exists" do
      vote_doc = instance_double(Google::Cloud::Firestore::DocumentSnapshot, exists?: true)
      vote_ref = instance_double(Google::Cloud::Firestore::DocumentReference, get: vote_doc)
      allow(firestore).to receive(:doc).with("mod_votes/#{doc_id}").and_return(vote_ref)
      allow(vote_ref).to receive(:delete)

      counter_ref = instance_double(Google::Cloud::Firestore::DocumentReference)
      allow(firestore).to receive(:doc).with("mod_vote_counts/#{mod_id}").and_return(counter_ref)
      allow(counter_ref).to receive(:set)

      result = described_class.remove!(mod_id, fingerprint)

      expect(result).to be true
      expect(vote_ref).to have_received(:delete)
      expect(counter_ref).to have_received(:set).with(
        { count: an_instance_of(Google::Cloud::Firestore::FieldValue) },
        merge: true
      )
    end

    it "returns false when vote does not exist" do
      vote_doc = instance_double(Google::Cloud::Firestore::DocumentSnapshot, exists?: false)
      vote_ref = instance_double(Google::Cloud::Firestore::DocumentReference, get: vote_doc)
      allow(firestore).to receive(:doc).with("mod_votes/#{doc_id}").and_return(vote_ref)

      result = described_class.remove!(mod_id, fingerprint)

      expect(result).to be false
    end
  end

  describe ".count_for" do
    it "returns the count when counter exists" do
      counter_doc = instance_double(Google::Cloud::Firestore::DocumentSnapshot, exists?: true, :[] => 42)
      counter_ref = instance_double(Google::Cloud::Firestore::DocumentReference, get: counter_doc)
      allow(firestore).to receive(:doc).with("mod_vote_counts/#{mod_id}").and_return(counter_ref)

      expect(described_class.count_for(mod_id)).to eq(42)
    end

    it "returns 0 when counter does not exist" do
      counter_doc = instance_double(Google::Cloud::Firestore::DocumentSnapshot, exists?: false)
      counter_ref = instance_double(Google::Cloud::Firestore::DocumentReference, get: counter_doc)
      allow(firestore).to receive(:doc).with("mod_vote_counts/#{mod_id}").and_return(counter_ref)

      expect(described_class.count_for(mod_id)).to eq(0)
    end
  end

  describe ".rate_limited?" do
    it "returns true when fingerprint exceeds rate limit" do
      query1 = instance_double(Google::Cloud::Firestore::Query)
      query2 = instance_double(Google::Cloud::Firestore::Query)
      results = Array.new(10) { instance_double(Google::Cloud::Firestore::DocumentSnapshot) }

      allow(firestore).to receive(:col).with("mod_votes").and_return(collection)
      allow(collection).to receive(:where).with(:fingerprint, :==, fingerprint).and_return(query1)
      allow(query1).to receive(:where).and_return(query2)
      allow(query2).to receive(:get).and_return(results)

      expect(described_class.rate_limited?(fingerprint)).to be true
    end

    it "returns false when under rate limit" do
      query1 = instance_double(Google::Cloud::Firestore::Query)
      query2 = instance_double(Google::Cloud::Firestore::Query)
      results = Array.new(3) { instance_double(Google::Cloud::Firestore::DocumentSnapshot) }

      allow(firestore).to receive(:col).with("mod_votes").and_return(collection)
      allow(collection).to receive(:where).with(:fingerprint, :==, fingerprint).and_return(query1)
      allow(query1).to receive(:where).and_return(query2)
      allow(query2).to receive(:get).and_return(results)

      expect(described_class.rate_limited?(fingerprint)).to be false
    end
  end
end

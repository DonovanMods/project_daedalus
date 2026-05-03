# frozen_string_literal: true

require "rails_helper"

RSpec.describe NexusMod do
  let(:firestore_client) { instance_double(Google::Cloud::Firestore::Client) }
  let(:firestore_collection) { instance_double(Google::Cloud::Firestore::CollectionReference) }

  def nexus_doc(mod_id: 12_345, name: "Better Building", author: "ModAuthor")
    instance_double(Google::Cloud::Firestore::DocumentSnapshot,
                    document_id: mod_id.to_s,
                    create_time: Time.now.utc,
                    update_time: Time.now.utc,
                    data: {
                      nexus_id: mod_id,
                      name: name,
                      author: author,
                      description: "A description",
                      summary: "Short summary",
                      version: "1.2.3",
                      image_url: "https://example.com/image.png",
                      mod_page_url: "https://www.nexusmods.com/icarus/mods/#{mod_id}",
                      endorsements: 42,
                      downloads: 1000
                    })
  end

  before do
    allow(Google::Cloud::Firestore).to receive(:new).and_return(firestore_client)
    allow(firestore_collection).to receive(:get).and_return([nexus_doc])
    allow(firestore_client).to receive(:col).with("nexus_mods").and_return(firestore_collection)
    Rails.cache.delete("firestore/nexus_mods")
  end

  described_class::ATTRIBUTES.each do |attr|
    it { is_expected.to respond_to(attr) }
  end

  describe "::COLLECTION" do
    it "points at the nexus_mods Firestore collection" do
      expect(described_class::COLLECTION).to eq("nexus_mods")
    end
  end

  describe ".all" do
    it "returns instances of NexusMod" do
      expect(described_class.all).to all(be_a(described_class))
    end

    it "loads documents from the nexus_mods collection" do
      expect(firestore_client).to receive(:col).with("nexus_mods")
      described_class.all
    end

    it "uses the document_id as the model id" do
      expect(described_class.all.first.id).to eq("12345")
    end
  end

  describe "Mod-compatible interface" do
    let(:mod) { described_class.all.first }

    it "reports as a nexus source" do
      expect(mod.nexus_source?).to be(true)
    end

    it "has a preferred_type of :nexus" do
      expect(mod.preferred_type).to eq(:nexus)
    end

    it "returns the Nexus page URL for any get_url call" do
      expect(mod.get_url(:anything)).to eq("https://www.nexusmods.com/icarus/mods/12345")
    end

    it "slugifies the name" do
      expect(mod.slug).to eq("better-building")
    end

    it "returns nil compatibility (not exposed by the Nexus API)" do
      expect(mod.compatibility).to be_nil
    end
  end
end

require "rails_helper"

RSpec.describe Firestore do
  let(:client_double) { double }
  let(:collection_double) { double }
  let(:firestore_mod) do
    instance_double(Google::Cloud::Firestore::DocumentSnapshot,
                    document_id: SecureRandom.uuid,
                    create_time: Time.now.utc,
                    update_time: Time.now.utc,
                    data: {
                      name: Faker::App.name,
                      author: Faker::App.author,
                      description: Faker::Lorem.sentence,
                      version: Faker::App.version,
                      compatibility: "w#{Random.rand(1..5)}",
                      fileType: %w[zip pak].sample,
                      fileURL: Faker::Internet.url,
                      imageURL: Faker::Internet.url,
                      readmeURL: Faker::Internet.url
                    })
  end
  let(:firestore_mods) { Array.new(5) { firestore_mod } }

  before do
    allow(collection_double).to receive(:get).and_return(firestore_mods)
    allow(client_double).to receive(:col).with("mods").and_return(collection_double)
    allow(Google::Cloud::Firestore).to receive(:new).with(credentials: Rails.application.credentials.firebase_keyfile.to_h).and_return(client_double)
  end

  describe "#mods" do
    it "returns an Array of Mod objects" do
      expect(described_class.new.mods).to all(be_a(Mod))
    end

    it "returns the correct number of mods" do
      expect(described_class.new.mods.count).to eq(5)
    end

    describe "given a mod with a filtered file type" do
      let(:firestore_exmod) do
        instance_double(Google::Cloud::Firestore::DocumentSnapshot,
                        document_id: SecureRandom.uuid,
                        create_time: Time.now.utc,
                        update_time: Time.now.utc,
                        data: {
                          name: Faker::App.name,
                          author: Faker::App.author,
                          description: Faker::Lorem.sentence,
                          version: Faker::App.version,
                          compatibility: "w#{Random.rand(1..5)}",
                          fileType: "EXMOD",
                          fileURL: Faker::Internet.url,
                          imageURL: Faker::Internet.url,
                          readmeURL: Faker::Internet.url
                        })
      end

      before do
        firestore_mods[0] = firestore_exmod
      end

      it "returns an Array of Mod objects" do
        expect(described_class.new.mods).to all(be_a(Mod))
      end

      it "filters out the EXMOD" do
        expect(described_class.new.mods.count).to eq(4)
      end
    end
  end
end

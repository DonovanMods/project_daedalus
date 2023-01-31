require "rails_helper"

RSpec.describe Mod do
  let(:firestore_client) { instance_double(Google::Cloud::Firestore::Client) }
  let(:firestore_collection) { instance_double(Google::Cloud::Firestore::CollectionReference) }
  let(:mod_firestore_obj) do
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
                      fileType: "ZIP",
                      fileURL: Faker::Internet.url,
                      imageURL: Faker::Internet.url,
                      readmeURL: Faker::Internet.url
                    })
  end

  before do
    allow(Google::Cloud::Firestore).to receive(:new).and_return(firestore_client)
    allow(firestore_collection).to receive(:get).and_return(Array.new(2, mod_firestore_obj))
    allow(firestore_client).to receive(:col).with("mods").and_return(firestore_collection)
  end

  described_class::ATTRIBUTES.each do |attr|
    it { is_expected.to respond_to(attr) }
  end

  describe "::SORTKEYS" do
    it "returns the sortkeys" do
      expect(described_class::SORTKEYS).to eq(%w[author name])
    end
  end

  describe "#self.all" do
    it "responds to all" do
      expect(described_class).to respond_to(:all)
    end

    it "returns instances of Mod" do
      expect(described_class.all).to all(be_a(described_class))
    end

    it "returns all mods" do
      expect(described_class.all.count).to eq(2)
    end
  end

  context "when the readme_url is present" do
    let(:readme_url) { Faker::Internet.url }
    let(:mod) { build(:mod, readme_url: readme_url) }
    let(:readme) { Faker::Lorem.paragraph }

    before do
      allow(Net::HTTP).to receive(:get).and_return(readme)
    end

    describe "#readme" do
      it "returns the readme" do
        expect(mod.readme).to eq(readme)
      end

      context "when readme_url is not a GitHub URL" do
        let(:readme_url) { Faker::Internet.url }

        it "uses the given readme_url" do
          mod.readme

          expect(Net::HTTP).to have_received(:get).with(URI(readme_url))
        end
      end

      context "when readme_url is a GitHub URL" do
        let(:readme_url) { "https://github.com/username/repo/raw/master/README.md" }

        before { mod.readme_url = readme_url }

        it "uses the corrected readme_url" do
          mod.readme

          expect(Net::HTTP).to have_received(:get).with(URI("https://raw.githubusercontent.com/username/repo/master/README.md"))
        end
      end
    end

    describe "#details" do
      it "returns the readme" do
        expect(mod.details).to eq(readme)
      end
    end
  end

  context "when the readme_url is not present" do
    let(:mod) { build(:mod, readme_url: "") }

    describe "#readme" do
      it "returns nil" do
        expect(mod.readme).to be_nil
      end
    end

    describe "#details" do
      context "when the long_description is present" do
        let(:long_description) { Faker::Lorem.paragraph }

        before { mod.long_description = long_description }

        it "returns the long_description" do
          expect(mod.details).to eq(long_description)
        end
      end

      context "when the long_description is not present" do
        let(:description) { Faker::Lorem.paragraph }

        before do
          mod.long_description = ""
          mod.description = description
        end

        it "returns the description" do
          expect(mod.details).to eq(description)
        end
      end
    end
  end

  describe "#filename" do
    let(:url) { Faker::Internet.url }
    let(:mod) { build(:mod, url: url) }

    it "returns the filename" do
      expect(mod.filename).to eq(url.split("/").last)
    end
  end

  describe "#updated_string" do
    let(:updated_at) { Faker::Date.backward }
    let(:mod) { build(:mod, updated_at: updated_at) }

    it "returns the updated string" do
      expect(mod.updated_string).to eq("Last Updated on #{updated_at.strftime('%B %d, %Y')}")
    end
  end

  describe "#version_string" do
    let(:version) { Faker::App.version }
    let(:compatibility) { Faker::App.version }
    let(:mod) { build(:mod, version: version, compatibility: compatibility) }

    it "returns the version and compatibility string" do
      expect(mod.version_string).to eq("v#{version} / #{compatibility}")
    end

    context "when the version is not present" do
      let(:version) { "" }

      it "returns only the compatibility string" do
        expect(mod.version_string).to eq(compatibility)
      end
    end

    context "when the compatibility is not present" do
      let(:compatibility) { "" }

      it "returns only the version string" do
        expect(mod.version_string).to eq("v#{version}")
      end
    end
  end
end

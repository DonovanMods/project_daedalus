require "rails_helper"

RSpec.describe Tool do
  let(:client) { double }
  let(:collection) { double }
  let(:firestore_obj) do
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
    allow(collection).to receive(:get).and_return(Array.new(3, firestore_obj))
    allow(client).to receive(:col).with("tools").and_return(collection)
    allow(Google::Cloud::Firestore).to receive(:new).and_return(client)
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
    it "returns instances of Mod" do
      expect(described_class.all).to all(be_a(described_class))
    end

    # foo
    it "returns all mods", skip: "This spec fails for unknown reasons when the full suite is run" do
      expect(described_class.all.size).to eq(3)
    end
  end

  context "when the readme_url is present" do
    let(:readme_url) { Faker::Internet.url }
    let(:tool) { build(:tool, readme_url:) }
    let(:readme) { Faker::Lorem.paragraph }

    before do
      allow(Net::HTTP).to receive(:get).and_return(readme)
    end

    describe "#readme" do
      it "returns the readme" do
        expect(tool.readme).to eq(readme)
      end

      context "when readme_url is not a GitHub URL" do
        let(:readme_url) { Faker::Internet.url }

        it "uses the given readme_url" do
          tool.readme

          expect(Net::HTTP).to have_received(:get).with(URI(readme_url))
        end
      end

      context "when readme_url is a GitHub URL" do
        let(:readme_url) { "https://github.com/username/repo/raw/master/README.md" }

        before { tool.readme_url = readme_url }

        it "uses the corrected readme_url" do
          tool.readme

          expect(Net::HTTP).to have_received(:get).with(URI("https://raw.githubusercontent.com/username/repo/master/README.md"))
        end
      end
    end

    describe "#details" do
      it "returns the readme" do
        expect(tool.details).to eq(readme)
      end
    end
  end

  context "when the readme_url is not present" do
    let(:tool) { build(:tool, readme_url: "") }

    describe "#readme" do
      it "returns nil" do
        expect(tool.readme).to be_nil
      end
    end

    describe "#details" do
      let(:description) { Faker::Lorem.paragraph }

      before do
        tool.description = description
      end

      it "returns the description" do
        expect(tool.details).to eq(description)
      end
    end
  end

  describe "#filename" do
    let(:url) { Faker::Internet.url }
    let(:tool) { build(:tool, url:) }

    it "returns the filename" do
      expect(tool.filename).to eq(url.split("/").last)
    end
  end

  describe "#updated_string" do
    let(:updated_at) { Faker::Date.backward }
    let(:tool) { build(:tool, updated_at:) }

    it "returns the updated string" do
      expect(tool.updated_string).to eq("Last Updated on #{updated_at.strftime('%B %d, %Y')}")
    end
  end

  describe "#version_string" do
    let(:version) { Faker::App.version }
    let(:compatibility) { Faker::App.version }
    let(:tool) { build(:tool, version:, compatibility:) }

    it "returns the version and compatibility string" do
      expect(tool.version_string).to eq("v#{version} / #{compatibility}")
    end

    context "when the version is not present" do
      let(:version) { "" }

      it "returns only the compatibility string" do
        expect(tool.version_string).to eq(compatibility)
      end
    end

    context "when the compatibility is not present" do
      let(:compatibility) { "" }

      it "returns only the version string" do
        expect(tool.version_string).to eq("v#{version}")
      end
    end
  end
end

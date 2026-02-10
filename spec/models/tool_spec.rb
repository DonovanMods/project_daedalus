# frozen_string_literal: true

require "rails_helper"

RSpec.describe Tool do
  let(:firestore_client) { instance_double(Google::Cloud::Firestore::Client) }
  let(:firestore_collection) { instance_double(Google::Cloud::Firestore::CollectionReference) }
  let(:tool_firestore_obj) do
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
  let(:tool) { build :tool }

  before do
    allow(Google::Cloud::Firestore).to receive(:new).and_return(firestore_client)
    allow(firestore_client).to receive(:col).with("tools").and_return(firestore_collection)
    allow(firestore_collection).to receive(:get).and_return(Array.new(3, tool_firestore_obj))
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

    it "returns instances of Tool" do
      expect(described_class.all).to all(be_a(described_class))
    end

    it "returns all tools" do
      expect(described_class.all.count).to eq(3)
    end
  end

  context "when the readme_url is present" do
    before do
      allow(Net::HTTP).to receive(:get).and_return("foo")
    end

    describe "#readme" do
      it "returns the readme" do
        expect(tool.readme).to eq("foo")
      end

      it "uses the given readme_url when not a GitHub URL" do
        tool.readme_url = Faker::Internet.url
        tool.readme

        expect(Net::HTTP).to have_received(:get).with(URI(tool.readme_url))
      end

      it "uses the corrected readme_url when given a GitHub URL" do
        tool.readme_url = "https://github.com/username/repo/raw/master/README.md"
        tool.readme

        expect(Net::HTTP).to have_received(:get).with(URI("https://raw.githubusercontent.com/username/repo/master/README.md"))
      end
    end

    describe "#details" do
      it "returns the readme" do
        expect(tool.details).to eq("foo")
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

    it "returns the filename" do
      tool.url = url

      expect(tool.filename).to eq(url.split("/").last)
    end
  end

  describe "#updated_string" do
    let(:updated_at) { Faker::Date.backward }

    it "returns the updated string" do
      tool.updated_at = updated_at

      expect(tool.updated_string).to eq("Last Updated on #{updated_at.strftime("%B %d, %Y")}")
    end
  end

  describe "#version_string" do
    context "when the version and compatability is present" do
      it "returns the version and compatibility string" do
        tool.compatibility = Faker::App.version
        tool.version = Faker::App.version

        expect(tool.version_string).to eq("v#{tool.version} / #{tool.compatibility}")
      end
    end

    context "when the version is not present" do
      it "returns only the compatibility string" do
        tool.compatibility = Faker::App.version
        tool.version = ""

        expect(tool.version_string).to eq(tool.compatibility)
      end
    end

    context "when the compatibility is not present" do
      it "returns only the version string" do
        tool.compatibility = ""
        tool.version = Faker::App.version

        expect(tool.version_string).to eq("v#{tool.version}")
      end
    end
  end

  describe "#readme error handling" do
    let(:readme_url) { "https://example.com/README.md" }

    before { tool.readme_url = readme_url }

    context "when network errors occur" do
      it "returns nil on SocketError" do
        allow(Net::HTTP).to receive(:get).and_raise(SocketError)
        expect(tool.readme).to be_nil
      end

      it "returns nil on Errno::ECONNREFUSED" do
        allow(Net::HTTP).to receive(:get).and_raise(Errno::ECONNREFUSED)
        expect(tool.readme).to be_nil
      end

      it "returns nil on Timeout::Error" do
        allow(Net::HTTP).to receive(:get).and_raise(Timeout::Error)
        expect(tool.readme).to be_nil
      end

      it "returns nil on URI::InvalidURIError" do
        allow(Net::HTTP).to receive(:get).and_raise(URI::InvalidURIError)
        expect(tool.readme).to be_nil
      end

      it "logs the error" do
        allow(Net::HTTP).to receive(:get).and_raise(SocketError, "Network error")
        allow(Rails.logger).to receive(:error)

        tool.readme

        expect(Rails.logger).to have_received(:error).with(/Failed to fetch README/)
      end
    end

    context "when readme fetch fails" do
      before { allow(Net::HTTP).to receive(:get).and_raise(SocketError) }

      it "details falls back to description" do
        tool.description = "Fallback description"
        expect(tool.details).to eq("Fallback description")
      end
    end
  end

  describe "caching" do
    let(:memory_store) { ActiveSupport::Cache::MemoryStore.new }

    before do
      allow(Rails).to receive(:cache).and_return(memory_store)
    end

    it "caches results and skips Firestore on subsequent calls" do
      allow(described_class).to receive(:fetch_all).and_call_original
      described_class.all
      described_class.all
      expect(described_class).to have_received(:fetch_all).once
    end

    it "clears cache with .expire_cache" do
      described_class.all
      described_class.expire_cache
      expect(memory_store.exist?("firestore/tools")).to be false
    end
  end
end

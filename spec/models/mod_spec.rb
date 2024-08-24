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
        files: {zip: Faker::Internet.url},
        imageURL: Faker::Internet.url,
        readmeURL: Faker::Internet.url
      })
  end
  let(:mod) { build :mod }

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
    before { allow(Net::HTTP).to receive(:get).and_return("foo") }

    describe "#readme" do
      let(:readme_url) { Faker::Internet.url }

      it "returns the readme" do
        expect(mod.readme).to eq("foo")
      end

      it "uses the given readme_url" do
        mod.readme_url = readme_url
        mod.readme

        expect(Net::HTTP).to have_received(:get).with(URI(readme_url))
      end

      it "uses the corrected readme_url" do
        mod.readme_url = "https://github.com/username/repo/raw/master/README.md"
        mod.readme

        expect(Net::HTTP).to have_received(:get).with(URI("https://raw.githubusercontent.com/username/repo/master/README.md"))
      end
    end

    describe "#details" do
      it "returns the readme" do
        expect(mod.details).to eq("foo")
      end
    end
  end

  context "when the readme_url is not present" do
    before { mod.readme_url = "" }

    describe "#readme" do
      it "returns nil" do
        expect(mod.readme).to be_nil
      end
    end

    describe "#details" do
      let(:description) { Faker::Lorem.paragraph }

      before do
        mod.description = description
      end

      it "returns the description" do
        expect(mod.details).to eq(description)
      end
    end
  end

  describe "#slug" do
    let(:name) { Faker::App.name }

    before { mod.name = name }

    it "returns mod name as a slug" do
      expect(mod.slug).to eq(name.parameterize)
    end
  end

  describe "#author_slug" do
    let(:author) { Faker::App.author }

    before { mod.author = author }

    it "returns the author name as a slug" do
      expect(mod.author_slug).to eq(author.parameterize)
    end
  end

  describe "#updated_string" do
    let(:updated_at) { Faker::Date.backward }

    before { mod.updated_at = updated_at }

    it "returns the updated string" do
      expect(mod.updated_string).to eq("Last Updated on #{updated_at.strftime("%B %d, %Y")}")
    end
  end

  describe "#version_string" do
    context "when the version and compatability is present" do
      it "returns the version and compatibility string" do
        mod.compatibility = Faker::App.version
        mod.version = Faker::App.version

        expect(mod.version_string).to eq("v#{mod.version} / #{mod.compatibility}")
      end
    end

    context "when the version is not present" do
      it "returns only the compatibility string" do
        mod.compatibility = Faker::App.version
        mod.version = ""

        expect(mod.version_string).to eq(mod.compatibility)
      end
    end

    context "when the compatibility is not present" do
      it "returns only the version string" do
        mod.compatibility = ""
        mod.version = Faker::App.version

        expect(mod.version_string).to eq("v#{mod.version}")
      end
    end
  end

  describe "#files?" do
    context "when given a files object" do
      it "returns true" do
        expect(mod.files?).to be true
      end
    end
  end

  %i[pak zip exmodz].each do |file_type|
    describe "##{file_type}?" do
      context "when given a #{file_type} object" do
        before { mod.files = {file_type.to_sym => Faker::Internet.url} }

        it "returns true" do
          expect(mod.send(:"#{file_type}?")).to be true
        end
      end

      context "when not given a pak object" do
        before { mod.files = {} }

        it "returns false" do
          expect(mod.send(:"#{file_type}?")).to be false
        end
      end
    end
  end

  context "when given a exmodz object" do
    describe "#exmodz?" do
      before { mod.files = {exmodz: Faker::Internet.url} }

      it "returns true" do
        expect(mod.exmodz?).to be true
      end
    end
  end

  describe "#preferred_type" do
    context "when given a pak object" do
      before do
        mod.files = {zip: Faker::Internet.url, pak: Faker::Internet.url, exmodz: Faker::Internet.url}
      end

      it "returns the preferred type" do
        expect(mod.preferred_type).to eq(:pak)
      end
    end

    context "when given a zip object" do
      before { mod.files = {zip: Faker::Internet.url, exmodz: Faker::Internet.url} }

      it "returns the preferred type" do
        expect(mod.preferred_type).to eq(:zip)
      end
    end

    context "when only given an exmod object" do
      before { mod.files = {exmod: Faker::Internet.url} }

      it "returns the preferred type" do
        expect(mod.preferred_type).to be_nil
      end
    end

    context "when only given an exmodz object" do
      before { mod.files = {exmodz: Faker::Internet.url} }

      it "returns the preferred type" do
        expect(mod.preferred_type).to be_nil
      end
    end
  end

  describe "#file_types" do
    context "when given a files object" do
      before { mod.files = {zip: Faker::Internet.url, pak: Faker::Internet.url, exmodz: Faker::Internet.url} }

      it "returns the file types" do
        expect(mod.file_types).to eq(%i[zip pak exmodz])
      end
    end
  end

  describe "#urls" do
    context "when given a files object" do
      it "returns an array of urls" do
        mod.files = {zip: Faker::Internet.url, pak: Faker::Internet.url, exmodz: Faker::Internet.url}

        expect(mod.urls).to eq([mod.files[:zip], mod.files[:pak], mod.files[:exmodz]])
      end
    end
  end

  describe "#get_url" do
    context "when given a files object" do
      before { mod.files = {zip: Faker::Internet.url} }

      it "returns the url" do
        expect(mod.get_url(:zip)).to eq(mod.files[:zip])
      end
    end
  end

  describe "#get_name" do
    context "when given a files object" do
      before { mod.files = {zip: Faker::Internet.url} }

      it "returns the name" do
        expect(mod.get_name(:zip)).to eq(mod.files[:zip].split("/").last)
      end
    end
  end

  describe "#types_string" do
    context "when given a files object" do
      before { mod.files = {zip: Faker::Internet.url, pak: Faker::Internet.url, exmodz: Faker::Internet.url} }

      it "returns the types string" do
        expect(mod.types_string).to eq("EXMODZ / PAK / ZIP")
      end
    end
  end
end

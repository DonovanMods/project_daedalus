require "rails_helper"

RSpec.describe Mod do
  described_class::ATTRIBUTES.each do |attr|
    it { is_expected.to respond_to(attr) }
  end

  describe "::SORTKEYS" do
    it "returns the sortkeys" do
      expect(described_class::SORTKEYS).to eq(%w[author name])
    end
  end

  context "when the readme_url is present" do
    let(:readme_url) { Faker::Internet.url }
    let(:mod) { build(:mod, readme_url:) }
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
    let(:mod) { build(:mod, url:) }

    it "returns the filename" do
      expect(mod.filename).to eq(url.split("/").last)
    end
  end

  describe "#updated_string" do
    let(:updated_at) { Faker::Date.backward }
    let(:mod) { build(:mod, updated_at:) }

    it "returns the updated string" do
      expect(mod.updated_string).to eq("Last Updated on #{updated_at.strftime('%B %d, %Y')}")
    end
  end

  describe "#version_string" do
    let(:version) { Faker::App.version }
    let(:compatibility) { Faker::App.version }
    let(:mod) { build(:mod, version:, compatibility:) }

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

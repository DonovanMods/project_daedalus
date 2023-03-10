require "rails_helper"

RSpec.describe Icarus::Profile do
  subject { profile }

  let(:profile) { described_class.parse(raw_json) }
  let(:raw_json) { File.read(Rails.root.join("spec/fixtures/Profile.json")) }

  describe "Class Methods" do
    subject { described_class }

    it { is_expected.to respond_to(:parse) }
    it { is_expected.to respond_to(:to_json) }

    describe ".parse" do
      subject { described_class.parse(raw_json) }

      it { is_expected.to be_a(described_class) }
    end

    describe ".to_json" do
      subject { described_class.to_json }

      it { is_expected.to be_a(String) }
      it { is_expected.to match(/"UserID":/) }
      it { is_expected.to match(/"MetaResources":/) }
      it { is_expected.to match(/"Talents":/) }
    end
  end

  describe "#credits" do
    before { profile.instance_variable_set(:@data, {"MetaResources" => [{"MetaRow" => "Credits", "Count" => 1_000}]}) }

    it { expect(profile.credits).to be_a(Integer) }

    it "returns the count" do
      expect(profile.credits).to eq(1_000)
    end
  end

  describe "#credits=" do
    it "Updates the credit value" do
      profile.credits = 100_000
      expect(profile.data["MetaResources"].find { |r| r["MetaRow"] == "Credits" }["Count"]).to eq(100_000)
    end
  end

  describe "#exotics" do
    before { profile.instance_variable_set(:@data, {"MetaResources" => [{"MetaRow" => "Exotic1", "Count" => 800}]}) }

    it { expect(profile.exotics).to be_a(Integer) }

    it "Returns the count" do
      expect(profile.exotics).to eq(800)
    end
  end

  describe "#exotics=" do
    it "Updates the exotics value" do
      profile.exotics = 8_000
      expect(profile.data["MetaResources"].find { |r| r["MetaRow"] == "Exotic1" }["Count"]).to eq(8_000)
    end
  end

  describe "#refund" do
    it { expect(profile.refund).to be_a(Integer) }

    it "returns the count" do
      expect(profile.refund).to eq(28)
    end
  end

  describe "#refund=" do
    it "Updates the refund value" do
      profile.refund = 100
      expect(profile.data["MetaResources"].find { |r| r["MetaRow"] == "Refund" }["Count"]).to eq(100)
    end
  end

  describe "#talents" do
    it { expect(profile.talents).to be_a(Hash) }

    it "Has the correct number of counts" do
      expect(profile.talents.count).to eq(profile.data["Talents"].count)
    end
  end

  describe "#to_json" do
    it { expect(profile.to_json).to be_a(String) }
  end
end

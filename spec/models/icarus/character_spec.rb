require "rails_helper"

RSpec.describe Icarus::Character do
  subject { character }

  let(:character) { described_class.parse(raw_json).first }
  let(:raw_json) { Rails.root.join("spec/fixtures/Characters.json").read }

  describe "Class Methods" do
    subject { described_class }

    it { is_expected.to respond_to(:all) }
    it { is_expected.to respond_to(:parse) }
    it { is_expected.to respond_to(:to_json) }

    describe ".all" do
      subject { described_class.all }

      it { is_expected.to be_a(Array) }
      it { is_expected.to all(be_a(described_class)) }
    end

    # rubocop:disable RSpec/NestedGroups
    describe ".loaded?" do
      context "when the data is loaded" do
        before { described_class.class_variable_set(:@@characters, [character]) }

        it { expect(described_class).to be_loaded }
      end

      context "when the data is not loaded" do
        before { described_class.class_variable_set(:@@characters, []) }

        it { expect(described_class).not_to be_loaded }
      end
    end
    # rubocop:enable RSpec/NestedGroups

    describe ".parse" do
      subject { described_class.parse(raw_json) }

      it { is_expected.to be_a(Array) }
      it { is_expected.to all(be_a(described_class)) }
    end

    describe ".to_json" do
      subject { described_class.parse(raw_json).to_json }

      it { is_expected.to be_a(String) }

      it "retuns the proper JSON format" do
        expect(described_class.to_json).to match(%r{"Characters.json": \[})
      end
    end
  end

  describe "#abandoned?" do
    it { is_expected.to respond_to(:abandoned?) }

    context "when not abandoned" do
      it { expect(character.abandoned?).to be(false) }
    end

    context "when abandoned" do
      before { character.instance_variable_set(:@data, {"IsAbandoned" => true}) }

      it { expect(character.abandoned?).to be(true) }
    end
  end

  describe "#abandoned=" do
    it "sets the value" do
      character.abandoned = true
      expect(character.data["IsAbandoned"]).to be(true)
    end
  end

  describe "#credits" do
    before { character.instance_variable_set(:@data, {"MetaResources" => [{"MetaRow" => "Credits", "Count" => 1_000}]}) }

    it { expect(character.credits).to be_a(Integer) }

    it "returns the count" do
      expect(character.credits).to eq(1_000)
    end
  end

  describe "#credits=" do
    it "Updates the credit value" do
      character.credits = 100_000
      expect(character.data["MetaResources"].find { |r| r["MetaRow"] == "Credits" }["Count"]).to eq(100_000)
    end
  end

  describe "#dead?" do
    context "when not dead" do
      it { expect(character.dead?).to be(false) }
    end

    context "when dead" do
      before { character.instance_variable_set(:@data, {"IsDead" => true}) }

      it { expect(character.dead?).to be(true) }
    end
  end

  describe "#dead=" do
    it "sets the value" do
      character.dead = true
      expect(character.data["IsDead"]).to be(true)
    end
  end

  describe "#exotics" do
    before { character.instance_variable_set(:@data, {"MetaResources" => [{"MetaRow" => "Exotic1", "Count" => 800}]}) }

    it { expect(character.exotics).to be_a(Integer) }

    it "Returns the count" do
      expect(character.exotics).to eq(800)
    end
  end

  describe "#exotics=" do
    it "Updates the exotics value" do
      character.exotics = 8_000
      expect(character.data["MetaResources"].find { |r| r["MetaRow"] == "Exotic1" }["Count"]).to eq(8_000)
    end
  end

  describe "#level" do
    it "returns the current level" do
      expect(character.level).to eq(25)
    end

    context "when level is 0" do
      before { character.instance_variable_set(:@data, {"XP" => nil}) }

      it "returns zero" do
        expect(character.level).to eq(0)
      end
    end

    context "when level is maxed" do
      before { character.instance_variable_set(:@data, {"XP" => 10_000_000}) }

      it "returns the max level" do
        expect(character.level).to eq(60)
      end
    end
  end

  describe "#level=" do
    it "updates XP" do
      character.level = 30
      expect(character.data["XP"]).to eq(1_400_001) # 1,400,000 + 1
    end

    context "when level is 0" do
      it "does not update XP" do
        expect { character.level = 0 }.not_to change { character.data["XP"] }
      end
    end

    context "when level is exceeded" do
      it "does not update XP" do
        expect { character.level = 100 }.not_to change { character.data["XP"] }
      end
    end
  end

  describe "#location" do
    it "returns the current location" do
      expect(character.location).to eq("Prospect_Conifer")
    end
  end

  describe "#name" do
    it "returns the Character name" do
      expect(character.name).to eq("DAEDALUS")
    end
  end

  describe "#refund" do
    it { expect(character.refund).to be_a(Integer) }

    it "returns the count" do
      expect(character.refund).to eq(28)
    end
  end

  describe "#talents" do
    it { expect(character.talents).to be_a(Hash) }

    it "Has the correct number of counts" do
      expect(character.talents.count).to eq(character.data["Talents"].count)
    end
  end

  describe "#to_json" do
    it { expect(character.to_json).to be_a(String) }

    it "returns the proper JSON format" do
      expect(character.to_json).to match(%r{"CharacterName": "DAEDALUS"})
    end
  end

  describe "#xp" do
    it { expect(character.xp).to be_a(Integer) }

    it "returns the count" do
      expect(character.xp).to eq(1_178_741)
    end
  end

  describe "#xp=" do
    it "sets the value" do
      character.xp = 2_000_000
      expect(character.data["XP"]).to eq(2_000_000)
    end
  end

  describe "#xp_debt" do
    it { expect(character.xp_debt).to be_a(Integer) }

    it "returns the count" do
      expect(character.xp_debt).to eq(0)
    end
  end

  describe "#xp_debt=" do
    it "sets the value" do
      character.xp_debt = 200
      expect(character.data["XP_Debt"]).to eq(200)
    end
  end

  describe "#xp_string" do
    it { expect(character.xp_string).to be_a(String) }

    context "when there is XP debt" do
      before { character.instance_variable_set(:@data, character.data.merge("XP_Debt" => 48)) }

      it "returns the count" do
        expect(character.xp_string).to eq("1,178,741 (48 debt)")
      end
    end

    context "when there is no XP debt" do
      it "returns the count" do
        expect(character.xp_string).to eq("1,178,741")
      end
    end
  end
end

require "rails_helper"

RSpec.describe Character do
  describe "Class Methods" do
    subject { described_class }

    let(:raw_json) { File.read(Rails.root.join("spec/fixtures/characters.json")) }

    it { is_expected.to respond_to(:all) }
    it { is_expected.to respond_to(:parse) }
    it { is_expected.to respond_to(:to_json) }

    describe ".all" do
      subject { described_class.all }

      it { is_expected.to be_a(Array) }
      it { is_expected.to all(be_a(described_class)) }
    end

    describe ".parse" do
      subject { described_class.parse(raw_json) }

      it { is_expected.to be_a(Array) }
      it { is_expected.to all(be_a(described_class)) }
    end
  end

  describe "Instance Methods" do
    let(:character) { described_class.new }

    subject { character }


  end
end

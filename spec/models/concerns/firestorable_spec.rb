require "rails_helper"

RSpec.describe Firestorable do
  subject(:firestorable) { test_class.new }

  let(:test_class) { Struct.new(:firestore) { include Firestorable } }

  describe "#firestore" do
    before do
      allow(Google::Cloud::Firestore).to receive(:new)
    end

    it "calls Google::Cloud::Firestore.new" do
      test_class.firestore

      expect(Google::Cloud::Firestore).to have_received(:new).with(hash_including(:credentials))
    end
  end
end

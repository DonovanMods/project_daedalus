# frozen_string_literal: true

require "rails_helper"

RSpec.describe Firestorable do
  subject(:firestorable) { test_class.new }

  let(:test_class) { Struct.new(:firestore) { include Firestorable } }

  describe "#firestore" do
    context "when credentials are properly configured" do
      before do
        allow(Rails.application.credentials).to receive(:firebase_keyfile).and_return({
                                                                                        type: "service_account",
                                                                                        project_id: "test-project"
                                                                                      })
        allow(Google::Cloud::Firestore).to receive(:new)
      end

      it "calls Google::Cloud::Firestore.new with credentials" do
        test_class.firestore

        expect(Google::Cloud::Firestore).to have_received(:new).with(hash_including(:credentials))
      end

      it "converts credentials to hash" do
        test_class.firestore

        expect(Google::Cloud::Firestore).to have_received(:new).with(
          credentials: hash_including(type: "service_account", project_id: "test-project")
        )
      end
    end

    context "when credentials are missing" do
      before do
        allow(Rails.application.credentials).to receive(:firebase_keyfile).and_return(nil)
      end

      it "raises a descriptive error" do
        expect do
          test_class.firestore
        end.to raise_error(RuntimeError, /Firebase credentials not configured/)
      end

      it "includes helpful setup instructions in error message" do
        expect do
          test_class.firestore
        end.to raise_error(/credentials:edit/)
      end
    end

    context "when credentials are empty" do
      before do
        allow(Rails.application.credentials).to receive(:firebase_keyfile).and_return({})
        allow(Google::Cloud::Firestore).to receive(:new)
      end

      it "passes empty hash to Firestore" do
        test_class.firestore

        expect(Google::Cloud::Firestore).to have_received(:new).with(credentials: {})
      end
    end
  end
end

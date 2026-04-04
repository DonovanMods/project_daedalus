# frozen_string_literal: true

require "rails_helper"

RSpec.describe Displayable do
  let(:mod) { build(:mod) }

  describe "#updated_ago" do
    context "when updated_at is nil" do
      before { mod.updated_at = nil }

      it "returns 'Unknown'" do
        expect(mod.updated_ago).to eq("Unknown")
      end
    end

    context "when updated_at is recent" do
      before { mod.updated_at = 5.minutes.ago }

      it "returns a time ago string" do
        expect(mod.updated_ago).to match(/\d+ minutes? ago/)
      end
    end

    context "when updated_at is days ago" do
      before { mod.updated_at = 3.days.ago }

      it "returns a time ago string with days" do
        expect(mod.updated_ago).to match(/\d+ days? ago/)
      end
    end

    context "when updated_at is months ago" do
      before { mod.updated_at = 2.months.ago }

      it "returns a time ago string with months" do
        expect(mod.updated_ago).to match(/about \d+ months? ago|about \d+ months? ago/)
      end
    end
  end
end

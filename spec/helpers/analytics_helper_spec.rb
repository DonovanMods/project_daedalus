# frozen_string_literal: true

require "rails_helper"

RSpec.describe AnalyticsHelper, type: :helper do
  describe "#freshness_indicator" do
    it "returns Fresh for 0 days" do
      result = helper.freshness_indicator(0)
      expect(result).to eq(label: "Fresh", css: "text-emerald-500")
    end

    it "returns Recent for 15 days" do
      result = helper.freshness_indicator(15)
      expect(result).to eq(label: "Recent", css: "text-icarus-500")
    end

    it "returns Aging for 60 days" do
      result = helper.freshness_indicator(60)
      expect(result).to eq(label: "Aging", css: "text-yellow-500")
    end

    it "returns Stale for 120 days" do
      result = helper.freshness_indicator(120)
      expect(result).to eq(label: "Stale", css: "text-red-400")
    end

    it "returns Unknown for nil" do
      result = helper.freshness_indicator(nil)
      expect(result).to eq(label: "Unknown", css: "text-slate-400")
    end
  end

  describe "#parse_week_number" do
    it "parses w125 format" do
      expect(helper.parse_week_number("w125")).to eq(125)
    end

    it "parses W42 (case-insensitive)" do
      expect(helper.parse_week_number("W42")).to eq(42)
    end

    it "returns nil for blank input" do
      expect(helper.parse_week_number("")).to be_nil
    end

    it "returns nil for non-matching string" do
      expect(helper.parse_week_number("latest")).to be_nil
    end
  end

  describe "#author_stats" do
    it "computes stats for an author" do
      mod1 = build_mod("Mod A", "Author1", %i[exmodz])
      mod2 = build_mod("Mod B", "Author1", %i[pak])
      mod3 = build_mod("Mod C", "Author2", %i[exmodz])
      all_mods = [mod1, mod2, mod3]

      result = helper.author_stats(mod1, all_mods)
      expect(result[:total_mods]).to eq(2)
      expect(result[:file_type_counts]).to include(exmodz: 1, pak: 1)
    end

    def build_mod(name, author, file_types)
      Mod.new(
        name: name, author: author,
        files: file_types.index_with { |_| "https://example.com/#{name.parameterize}.zip" },
        created_at: Time.current - 30.days, updated_at: Time.current - 2.days
      )
    end
  end
end

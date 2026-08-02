# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Mods Type Filtering", type: :request do
  let(:pak_mod) { build(:mod, name: "Pak Only Mod", author: "Author One", files: { pak: "https://example.com/mod.pak" }) }
  let(:zip_mod) { build(:mod, name: "Zip Only Mod", author: "Author One", files: { zip: "https://example.com/mod.zip" }) }
  let(:exmod_mod) { build(:mod, name: "Exmod Only Mod", author: "Author Three", files: { exmod: "https://example.com/mod.exmod" }) }
  let(:exmodz_mod) { build(:mod, name: "Exmodz Only Mod", author: "Author Four", files: { exmodz: "https://example.com/mod.exmodz" }) }

  before do
    allow(Mod).to receive(:all).and_return([pak_mod, zip_mod, exmod_mod, exmodz_mod])
  end

  describe "GET /mods?type=pak" do
    it "shows only mods with pak files" do
      get mods_path(type: "pak")

      expect(response.body).to include("Pak Only Mod")
      expect(response.body).not_to include("Zip Only Mod")
      expect(response.body).not_to include("Exmod Only Mod")
      expect(response.body).not_to include("Exmodz Only Mod")
    end
  end

  describe "GET /mods?type=zip" do
    it "shows only mods with zip files" do
      get mods_path(type: "zip")

      expect(response.body).to include("Zip Only Mod")
      expect(response.body).not_to include("Pak Only Mod")
    end
  end

  describe "GET /mods?type=exmod" do
    it "shows mods with exmod or exmodz files" do
      get mods_path(type: "exmod")

      expect(response.body).to include("Exmod Only Mod")
      expect(response.body).to include("Exmodz Only Mod")
      expect(response.body).not_to include("Pak Only Mod")
      expect(response.body).not_to include("Zip Only Mod")
    end
  end

  describe "GET /mods?type=all" do
    it "shows all mods" do
      get mods_path(type: "all")

      expect(response.body).to include("Pak Only Mod")
      expect(response.body).to include("Zip Only Mod")
      expect(response.body).to include("Exmod Only Mod")
      expect(response.body).to include("Exmodz Only Mod")
    end
  end

  describe "GET /mods?type=garbage" do
    it "shows all mods" do
      get mods_path(type: "garbage")

      expect(response.body).to include("Pak Only Mod")
      expect(response.body).to include("Zip Only Mod")
    end
  end

  describe "GET /mods with query and type combined" do
    it "applies both filters" do
      get mods_path(query: "Only Mod", type: "pak")

      expect(response.body).to include("Pak Only Mod")
      expect(response.body).not_to include("Zip Only Mod")
    end

    it "returns nothing when query matches but type does not" do
      get mods_path(query: "Zip Only", type: "pak")

      expect(response.body).not_to include("Zip Only Mod")
    end
  end

  describe "GET /mods/:author?type=pak" do
    it "applies the type filter on author pages" do
      get mods_author_path(author: pak_mod.author_slug, type: "pak")

      expect(response.body).to include("Pak Only Mod")
      expect(response.body).not_to include("Zip Only Mod")
    end
  end
end

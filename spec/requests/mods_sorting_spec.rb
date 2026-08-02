# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Mods Sorting", type: :request do
  let(:older_mod) do
    build(:mod, name: "Aardvark Mod", author: "Zeb", files: { pak: "https://example.com/a.pak" },
                updated_at: 3.days.ago)
  end
  let(:newer_mod) do
    build(:mod, name: "Zebra Mod", author: "Amy", files: { zip: "https://example.com/z.zip" },
                updated_at: 1.hour.ago)
  end

  before do
    allow(Mod).to receive(:all).and_return([older_mod, newer_mod])
  end

  def positions(body, *names)
    names.map { |name| body.index(name) }
  end

  describe "default order" do
    it "lists most recently updated first" do
      get mods_path

      zebra, aardvark = positions(response.body, "Zebra Mod", "Aardvark Mod")
      expect(zebra).to be < aardvark
    end
  end

  describe "GET /mods?sort=name" do
    it "sorts by name ascending by default" do
      get mods_path(sort: "name")

      aardvark, zebra = positions(response.body, "Aardvark Mod", "Zebra Mod")
      expect(aardvark).to be < zebra
    end

    it "honors dir=desc" do
      get mods_path(sort: "name", dir: "desc")

      zebra, aardvark = positions(response.body, "Zebra Mod", "Aardvark Mod")
      expect(zebra).to be < aardvark
    end
  end

  describe "invalid params" do
    it "falls back to updated desc for unknown sort" do
      get mods_path(sort: "bogus")

      zebra, aardvark = positions(response.body, "Zebra Mod", "Aardvark Mod")
      expect(zebra).to be < aardvark
    end

    it "falls back to the column default for unknown dir" do
      get mods_path(sort: "name", dir: "sideways")

      aardvark, zebra = positions(response.body, "Aardvark Mod", "Zebra Mod")
      expect(aardvark).to be < zebra
    end
  end

  describe "composition with filters" do
    it "sorts the type-filtered set" do
      pak_two = build(:mod, name: "Bison Mod", author: "Cal", files: { pak: "https://example.com/b.pak" },
                            updated_at: 2.days.ago)
      allow(Mod).to receive(:all).and_return([older_mod, newer_mod, pak_two])

      get mods_path(type: "pak", sort: "name", dir: "desc")

      expect(response.body).not_to include("Zebra Mod")
      bison, aardvark = positions(response.body, "Bison Mod", "Aardvark Mod")
      expect(bison).to be < aardvark
    end
  end
end

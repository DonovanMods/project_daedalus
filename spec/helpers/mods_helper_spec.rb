# frozen_string_literal: true

require "rails_helper"

RSpec.describe ModsHelper, type: :helper do
  describe "mod_detail_path routing" do
    let(:mod) { build(:mod, name: "Test Mod", author: "Test Author") }

    it "generates correct path with author and slug" do
      path = mod_detail_path(author: mod.author_slug, slug: mod.slug)

      expect(path).to eq("/mods/#{mod.author_slug}/#{mod.slug}")
    end

    it "generates correct path with analytics parameter" do
      path = mod_detail_path(author: mod.author_slug, slug: mod.slug, analytics: true)

      expect(path).to eq("/mods/#{mod.author_slug}/#{mod.slug}?analytics=true")
    end

    it "requires both author and slug parameters" do
      expect {
        mod_detail_path(mod.author, analytics: true)
      }.to raise_error(ActionController::UrlGenerationError)
    end
  end
end

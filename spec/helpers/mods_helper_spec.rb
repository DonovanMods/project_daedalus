# frozen_string_literal: true

require "rails_helper"

RSpec.describe ModHelper, type: :helper do
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

  describe "#raw_url" do
    it "returns URL unchanged for non-GitHub URLs" do
      url = "https://example.com/file.zip"
      expect(helper.raw_url(url)).to eq(url)
    end

    it "converts GitHub blob URLs to raw.githubusercontent.com" do
      url = "https://github.com/user/repo/blob/main/README.md"
      result = helper.raw_url(url)
      expect(result).to eq("https://raw.githubusercontent.com/user/repo/main/README.md")
      expect(result).not_to include("/blob/")
    end

    it "handles raw.githubusercontent.com URLs without modification" do
      url = "https://raw.githubusercontent.com/user/repo/main/README.md"
      expect(helper.raw_url(url)).to eq(url)
    end

    it "handles nil URL gracefully" do
      expect(helper.raw_url(nil)).to be_nil
    end

    it "handles empty string URL" do
      expect(helper.raw_url("")).to eq("")
    end

    it "preserves query parameters in GitHub URLs" do
      url = "https://github.com/user/repo/blob/main/file.md?raw=true"
      result = helper.raw_url(url)
      expect(result).to eq("https://raw.githubusercontent.com/user/repo/main/file.md?raw=true")
      expect(result).to include("?raw=true")
    end

    it "handles GitHub URLs with different branch names" do
      url = "https://github.com/user/repo/blob/develop/README.md"
      result = helper.raw_url(url)
      expect(result).to eq("https://raw.githubusercontent.com/user/repo/develop/README.md")
      expect(result).to include("/develop/")
    end

    it "handles non-HTTP URLs" do
      url = "ftp://example.com/file.zip"
      expect(helper.raw_url(url)).to eq(url)
    end
  end
end

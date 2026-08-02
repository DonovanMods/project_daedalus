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
      expect do
        mod_detail_path(mod.author, analytics: true)
      end.to raise_error(ActionController::UrlGenerationError)
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

  describe "#download_button_classes" do
    it "returns emerald classes for pak" do
      expect(helper.download_button_classes(:pak))
        .to eq("bg-emerald-600 hover:bg-emerald-700 focus:ring-emerald-400")
    end

    it "returns indigo classes for zip" do
      expect(helper.download_button_classes(:zip))
        .to eq("bg-indigo-600 hover:bg-indigo-700 focus:ring-indigo-500")
    end

    it "returns icarus classes for exmodz" do
      expect(helper.download_button_classes(:exmodz))
        .to eq("bg-icarus-500 hover:bg-icarus-600 focus:ring-icarus-400")
    end

    it "returns icarus classes for exmod" do
      expect(helper.download_button_classes(:exmod))
        .to eq("bg-icarus-500 hover:bg-icarus-600 focus:ring-icarus-400")
    end

    it "falls back to icarus classes for unknown types" do
      expect(helper.download_button_classes(:tarball))
        .to eq("bg-icarus-500 hover:bg-icarus-600 focus:ring-icarus-400")
    end

    it "accepts string types" do
      expect(helper.download_button_classes("PAK"))
        .to eq("bg-emerald-600 hover:bg-emerald-700 focus:ring-emerald-400")
    end
  end

  describe "#effective_download_type" do
    let(:mod) { build(:mod, files: { pak: Faker::Internet.url, zip: Faker::Internet.url }) }

    it "returns the filtered type when a filter is active" do
      allow(helper).to receive(:params).and_return({ type: "pak" }.with_indifferent_access)
      expect(helper.effective_download_type(mod)).to eq(:pak)
    end

    it "returns preferred_type when no filter is active" do
      allow(helper).to receive(:params).and_return({}.with_indifferent_access)
      expect(helper.effective_download_type(mod)).to eq(:zip)
    end
  end

  describe "#sort_link" do
    before do
      allow(helper).to receive(:params).and_return({ query: "ice", type: "pak" }.with_indifferent_access)
      allow(helper.request).to receive(:path).and_return("/mods")
    end

    context "when the column is inactive" do
      it "links with the column's first-click default and no arrow" do
        html = helper.sort_link("Name", "name", current_sort: "updated", current_dir: "desc")

        expect(html).to include("sort=name")
        expect(html).to include("dir=asc")
        expect(html).to include(">Name</a>")
        expect(html).not_to include("▲")
        expect(html).not_to include("▼")
      end

      it "preserves query and type params and drops page" do
        allow(helper).to receive(:params)
          .and_return({ query: "ice", type: "pak", page: "3" }.with_indifferent_access)

        html = helper.sort_link("Name", "name", current_sort: "updated", current_dir: "desc")

        expect(html).to include("query=ice")
        expect(html).to include("type=pak")
        expect(html).not_to include("page=")
      end
    end

    context "when the column is active" do
      it "toggles direction and shows the ascending arrow" do
        html = helper.sort_link("Name", "name", current_sort: "name", current_dir: "asc")

        expect(html).to include("dir=desc")
        expect(html).to include("▲")
      end
    end

    context "when the column is active descending" do
      it "shows the descending arrow and toggles to asc" do
        html = helper.sort_link("Updated", "updated", current_sort: "updated", current_dir: "desc")

        expect(html).to include("dir=asc")
        expect(html).to include("▼")
      end
    end
  end
end

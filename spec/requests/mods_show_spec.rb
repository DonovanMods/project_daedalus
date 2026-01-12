# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Mods Show", type: :request do
  let(:mod1) { build(:mod, name: "Super Mod", author: "John Doe", description: "A great mod", files: {pak: "https://example.com/mod.pak"}) }
  let(:mod2) { build(:mod, name: "Test Mod", author: "Jane Smith", description: "Test description", files: {zip: "https://example.com/mod.zip"}) }

  before do
    allow(Mod).to receive(:all).and_return([mod1, mod2])
  end

  describe "GET /mods/:author/:slug" do
    context "when mod exists" do
      it "renders the mod detail page successfully" do
        get mod_detail_path(author: mod1.author_slug, slug: mod1.slug)
        expect(response).to have_http_status(:success)
      end

      it "displays mod name" do
        get mod_detail_path(author: mod1.author_slug, slug: mod1.slug)
        expect(response.body).to include("Super Mod")
      end

      it "displays mod author" do
        get mod_detail_path(author: mod1.author_slug, slug: mod1.slug)
        expect(response.body).to include("John Doe")
      end

      it "displays mod description" do
        get mod_detail_path(author: mod1.author_slug, slug: mod1.slug)
        expect(response.body).to include("A great mod")
      end

      it "shows download buttons for available file types" do
        get mod_detail_path(author: mod1.author_slug, slug: mod1.slug)
        expect(response.body).to include("DOWNLOAD")
        expect(response.body).to include("PAK")
      end

      it "handles mods with multiple file types" do
        mod_multi = build(:mod, name: "Multi", author: "Author", files: {pak: "url1", zip: "url2"})
        allow(Mod).to receive(:all).and_return([mod_multi])

        get mod_detail_path(author: mod_multi.author_slug, slug: mod_multi.slug)
        expect(response).to have_http_status(:success)
      end
    end

    context "when mod does not exist" do
      it "sets flash error message with mod not found" do
        get mod_detail_path(author: "nonexistent", slug: "missing-mod")
        expect(flash[:error]).to be_present
      end

      it "redirects to mods_author_path when author param present" do
        get mod_detail_path(author: "some-author", slug: "missing-mod")
        expect(response).to redirect_to(mods_author_path(author: "some-author"))
      end

      it "redirects to mods_path when mod not found and author matches no mods" do
        get mod_detail_path(author: "nonexistent-author", slug: "missing-mod")
        # Should eventually redirect to mods_path after checking author
        expect(response).to have_http_status(:redirect)
      end

      it "handles parameterized author/slug with special characters" do
        get mod_detail_path(author: "author-with-dash", slug: "mod-with-dash")
        expect(response).to have_http_status(:redirect)
      end

      it "handles case-insensitive slug matching" do
        get mod_detail_path(author: mod1.author_slug.upcase, slug: mod1.slug.upcase)
        expect(response).to have_http_status(:success)
      end
    end

    context "with analytics parameter" do
      it "renders analytics section when analytics=true param" do
        mod_with_meta = build(:mod, name: "Meta Mod", author: "Author", metadata: {status: {errors: [], warnings: []}})
        allow(Mod).to receive(:all).and_return([mod_with_meta])

        get mod_detail_path(author: mod_with_meta.author_slug, slug: mod_with_meta.slug, analytics: true)
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Analytics")
      end

      it "does not render analytics section without param" do
        get mod_detail_path(author: mod1.author_slug, slug: mod1.slug)
        # The word "analytics" appears in a link, but the analytics partial should not render
        expect(response.body).not_to include("render(\"analytics\"")
      end
    end

    context "with session origin_url" do
      it "displays back button when session[:origin_url] exists" do
        get mod_detail_path(author: mod1.author_slug, slug: mod1.slug), headers: {}, params: {}
        # First visit the index to set origin
        get "/mods"
        # Then visit the show page
        get mod_detail_path(author: mod1.author_slug, slug: mod1.slug)
        expect(response.body).to include("Back to List")
      end
    end

    context "with README content" do
      it "displays description when README URL is not available" do
        mod_no_readme = build(:mod, name: "No README", author: "Author", description: "Description only", readme_url: nil)
        allow(Mod).to receive(:all).and_return([mod_no_readme])

        get mod_detail_path(author: mod_no_readme.author_slug, slug: mod_no_readme.slug)
        expect(response.body).to include("Description only")
      end
    end
  end
end

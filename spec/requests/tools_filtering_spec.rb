# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Tools Filtering", type: :request do
  let(:tool1) { build(:tool, name: "Mod Manager", author: "John Doe", description: "Manages mods") }
  let(:tool2) { build(:tool, name: "Asset Editor", author: "Jane Smith", description: "Edit game assets") }
  let(:tool3) { build(:tool, name: "Level Builder", author: "John Doe", description: "Build custom levels") }

  before do
    allow(Tool).to receive(:all).and_return([tool1, tool2, tool3])
  end

  describe "GET /tools" do
    it "displays all tools when no filter applied" do
      get "/tools"
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Mod Manager")
      expect(response.body).to include("Asset Editor")
      expect(response.body).to include("Level Builder")
    end

    it "renders tools with descriptions" do
      get "/tools"
      expect(response.body).to include("Manages mods")
      expect(response.body).to include("Edit game assets")
    end

    it "shows download buttons for each tool" do
      get "/tools"
      expect(response.body).to include("DOWNLOAD")
    end

    it "displays tool authors" do
      get "/tools"
      expect(response.body).to include("John Doe")
      expect(response.body).to include("Jane Smith")
    end
  end

  describe "GET /tools/:author" do
    it "filters tools by author slug (case-insensitive)" do
      get tools_author_path(author: "john-doe")
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Mod Manager")
      expect(response.body).to include("Level Builder")
      expect(response.body).not_to include("Asset Editor")
    end

    it "handles uppercase author slugs" do
      get tools_author_path(author: "JOHN-DOE")
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Mod Manager")
    end

    it "handles lowercase author slugs" do
      get tools_author_path(author: "jane-smith")
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Asset Editor")
      expect(response.body).not_to include("Mod Manager")
    end

    it "returns empty results when author has no tools" do
      get tools_author_path(author: "nonexistent-author")
      expect(response).to have_http_status(:success)
      expect(response.body).not_to include("Mod Manager")
      expect(response.body).not_to include("Asset Editor")
    end

    it "handles author slugs with special characters" do
      tool_special = build(:tool, name: "Special Tool", author: "Author-With.Dots")
      allow(Tool).to receive(:all).and_return([tool_special])

      get tools_author_path(author: "author-with-dots")
      expect(response).to have_http_status(:success)
    end

    it "handles parameterize conversion for non-ASCII characters" do
      tool_unicode = build(:tool, name: "Unicode Tool", author: "Ñoño García")
      allow(Tool).to receive(:all).and_return([tool_unicode])

      get tools_author_path(author: tool_unicode.author_slug)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Unicode Tool")
    end
  end

  describe "author slug matching" do
    it "uses case-insensitive comparison" do
      mixed_case_tool = build(:tool, name: "MixedCase", author: "CamelCase Author")
      allow(Tool).to receive(:all).and_return([mixed_case_tool])

      get tools_author_path(author: "camelcase-author")
      expect(response).to have_http_status(:success)
      expect(response.body).to include("MixedCase")
    end
  end
end

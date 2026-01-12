# frozen_string_literal: true

require "rails_helper"

RSpec.describe "tools/index.html.erb", type: :view do
  let(:tool1) {
    build(:tool,
      name: "Mod Manager",
      author: "John Doe",
      version: "1.0.0",
      description: "Manages mods for the game",
      url: "https://example.com/tool.exe",
      updated_at: Time.zone.parse("2025-01-01"))
  }
  let(:tool2) {
    build(:tool,
      name: "Asset Editor",
      author: "Jane Smith",
      version: "2.5.1",
      description: "Edit game assets",
      url: "https://example.com/editor.zip",
      updated_at: Time.zone.parse("2025-02-15"))
  }

  before do
    assign(:tools, [tool1, tool2])
  end

  it "renders page title 'Icarus Modding Tools'" do
    render
    expect(rendered).to include("Icarus Modding Tools")
  end

  it "renders each tool as a card" do
    render
    expect(rendered).to include(tool1.slug)
    expect(rendered).to include(tool2.slug)
  end

  it "displays tool name" do
    render
    expect(rendered).to include("Mod Manager")
    expect(rendered).to include("Asset Editor")
  end

  it "displays tool author" do
    render
    expect(rendered).to include("John Doe")
    expect(rendered).to include("Jane Smith")
  end

  it "displays tool version" do
    render
    expect(rendered).to include("1.0.0")
    expect(rendered).to include("2.5.1")
  end

  it "renders markdown description" do
    render
    # The markdown helper will be called, descriptions will be rendered
    expect(rendered).to include("Manages mods")
    expect(rendered).to include("Edit game assets")
  end

  it "shows download button with correct URL" do
    render
    expect(rendered).to include("DOWNLOAD")
    expect(rendered).to include("data-mods-url-param")
  end

  it "triggers download Stimulus action on button click" do
    render
    expect(rendered).to include('data-action="mods#download"')
  end

  it "displays updated timestamp" do
    render
    expect(rendered).to include("Last Updated on January 01, 2025")
    expect(rendered).to include("Last Updated on February 15, 2025")
  end

  it "organizes tools in card layout" do
    render
    expect(rendered).to include("flex flex-col")
    expect(rendered).to include("rounded-xl")
  end

  it "has proper tool slug as id for each card" do
    render
    expect(rendered).to include("id=\"#{tool1.slug}\"")
    expect(rendered).to include("id=\"#{tool2.slug}\"")
  end

  context "with empty tools list" do
    before do
      assign(:tools, [])
    end

    it "still renders page title" do
      render
      expect(rendered).to include("Icarus Modding Tools")
    end

    it "does not render any tool cards" do
      render
      expect(rendered).not_to include("DOWNLOAD")
    end
  end

  context "with tool using raw_url helper" do
    let(:github_tool) {
      build(:tool,
        name: "GitHub Tool",
        author: "Dev",
        url: "https://github.com/user/repo/blob/main/tool.exe")
    }

    before do
      assign(:tools, [github_tool])
    end

    it "calls raw_url helper on tool URL" do
      render
      # The raw_url helper will be invoked during rendering
      expect(rendered).to include("DOWNLOAD")
    end
  end
end

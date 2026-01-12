# frozen_string_literal: true

require "rails_helper"

RSpec.describe "mods/_mod.html.erb", type: :view do
  let(:mod) {
    build(:mod,
      name: "Test Mod",
      author: "Test Author",
      version: "1.0.0",
      compatibility: "w5",
      description: "A test mod",
      files: {pak: "https://example.com/mod.pak"})
  }

  it "renders mod name" do
    render partial: "mods/mod", locals: {mod: mod}
    expect(rendered).to include("Test Mod")
  end

  it "renders author name" do
    render partial: "mods/mod", locals: {mod: mod}
    expect(rendered).to include("Test Author")
  end

  it "renders version when present" do
    render partial: "mods/mod", locals: {mod: mod}
    expect(rendered).to include("1.0.0")
  end

  it "renders compatibility when present" do
    render partial: "mods/mod", locals: {mod: mod}
    expect(rendered).to include("w5")
  end

  it "renders description" do
    render partial: "mods/mod", locals: {mod: mod}
    expect(rendered).to include("A test mod")
  end

  it "renders download button for preferred_type when available" do
    render partial: "mods/mod", locals: {mod: mod}
    expect(rendered).to include("Download")
    expect(rendered).to include("PAK")
  end

  it "has click handler for navigateTo" do
    render partial: "mods/mod", locals: {mod: mod}
    expect(rendered).to include('data-action="click->mods#navigateTo"')
  end

  it "includes correct mod_detail_path in data attribute" do
    render partial: "mods/mod", locals: {mod: mod}
    # Path uses mod.author (which gets URL encoded), not author_slug
    expect(rendered).to include("data-mods-path-param=\"/mods/Test%20Author/test-mod\"")
  end

  it "triggers download Stimulus action on button click" do
    render partial: "mods/mod", locals: {mod: mod}
    expect(rendered).to include('data-action="mods#download"')
  end

  context "with nil compatibility" do
    let(:mod_no_compat) {
      build(:mod,
        name: "No Compat",
        author: "Author",
        compatibility: nil,
        files: {zip: "https://example.com/mod.zip"})
    }

    it "handles nil compatibility gracefully" do
      expect {
        render partial: "mods/mod", locals: {mod: mod_no_compat}
      }.not_to raise_error
    end

    it "does not crash on downcase" do
      render partial: "mods/mod", locals: {mod: mod_no_compat}
      expect(rendered).to include("No Compat")
    end
  end

  context "with ZIP file type" do
    let(:mod_zip) {
      build(:mod,
        name: "ZIP Mod",
        author: "Author",
        files: {zip: "https://example.com/mod.zip"})
    }

    it "shows ZIP download button" do
      render partial: "mods/mod", locals: {mod: mod_zip}
      expect(rendered).to include("ZIP")
    end
  end

  context "with no preferred file type" do
    let(:mod_no_files) {
      build(:mod,
        name: "No Files",
        author: "Author",
        files: {exmodz: "https://example.com/mod.exmodz"})
    }

    it "does not show download button" do
      render partial: "mods/mod", locals: {mod: mod_no_files}
      expect(rendered).not_to include("Download PAK")
      expect(rendered).not_to include("Download ZIP")
    end
  end
end

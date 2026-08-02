# frozen_string_literal: true

require "rails_helper"

RSpec.describe "mods/_mod.html.erb", type: :view do
  let(:mod) do
    build(:mod,
          name: "Test Mod",
          author: "Test Author",
          version: "1.0.0",
          compatibility: "w5",
          description: "A test mod",
          files: { pak: "https://example.com/mod.pak" })
  end

  it "renders mod name" do
    render partial: "mods/mod", locals: { mod: mod }
    expect(rendered).to include("Test Mod")
  end

  it "renders author name" do
    render partial: "mods/mod", locals: { mod: mod }
    expect(rendered).to include("Test Author")
  end

  it "renders version when present" do
    render partial: "mods/mod", locals: { mod: mod }
    expect(rendered).to include("1.0.0")
  end

  it "renders compatibility when present" do
    render partial: "mods/mod", locals: { mod: mod }
    expect(rendered).to include("w5")
  end

  it "renders description" do
    render partial: "mods/mod", locals: { mod: mod }
    expect(rendered).to include("A test mod")
  end

  it "renders download button labeled with only the format name" do
    render partial: "mods/mod", locals: { mod: mod }
    expect(rendered).to include(">PAK<")
    expect(rendered).not_to include("Download")
    expect(rendered).to include("bg-emerald-600")
  end

  it "has click handler for navigateTo" do
    render partial: "mods/mod", locals: { mod: mod }
    expect(rendered).to include('data-action="click->mods#navigateTo"')
  end

  it "includes correct mod_detail_path in data attribute" do
    render partial: "mods/mod", locals: { mod: mod }
    # Path uses mod.author_slug (parameterized) for cleaner URLs
    expect(rendered).to include('data-mods-path-param="/mods/test-author/test-mod"')
  end

  it "triggers download Stimulus action on button click" do
    render partial: "mods/mod", locals: { mod: mod }
    expect(rendered).to include('data-action="mods#download"')
  end

  context "with nil compatibility" do
    let(:mod_no_compat) do
      build(:mod,
            name: "No Compat",
            author: "Author",
            compatibility: nil,
            files: { zip: "https://example.com/mod.zip" })
    end

    it "handles nil compatibility gracefully" do
      expect do
        render partial: "mods/mod", locals: { mod: mod_no_compat }
      end.not_to raise_error
    end

    it "does not crash on downcase" do
      render partial: "mods/mod", locals: { mod: mod_no_compat }
      expect(rendered).to include("No Compat")
    end
  end

  context "with ZIP file type" do
    let(:mod_zip) do
      build(:mod,
            name: "ZIP Mod",
            author: "Author",
            files: { zip: "https://example.com/mod.zip" })
    end

    it "shows ZIP download button" do
      render partial: "mods/mod", locals: { mod: mod_zip }
      expect(rendered).to include("ZIP")
    end
  end

  context "with only an exmodz file" do
    let(:mod_no_files) do
      build(:mod,
            name: "No Files",
            author: "Author",
            files: { exmodz: "https://example.com/mod.exmodz" })
    end

    it "shows the exmodz button in icarus gold" do
      render partial: "mods/mod", locals: { mod: mod_no_files }
      expect(rendered).to include(">EXMODZ<")
      expect(rendered).to include("bg-icarus-500")
      expect(rendered).not_to include("Download")
    end
  end

  context "with no files" do
    let(:mod_empty_files) do
      build(:mod,
            name: "Empty Files",
            author: "Author",
            files: {})
    end

    it "does not render a download button" do
      render partial: "mods/mod", locals: { mod: mod_empty_files }
      expect(rendered).not_to include("<button")
    end
  end

  context "with an active type filter and a multi-format mod" do
    let(:multi_mod) do
      build(:mod,
            name: "Multi Format",
            author: "Author",
            files: { pak: "https://example.com/m.pak", zip: "https://example.com/m.zip" })
    end

    it "offers the filtered type instead of the preferred one" do
      allow(view).to receive(:params).and_return({ type: "pak" }.with_indifferent_access)
      render partial: "mods/mod", locals: { mod: multi_mod }

      expect(rendered).to include(">PAK<")
      expect(rendered).to include("bg-emerald-600")
      expect(rendered).not_to include(">ZIP<")
    end
  end
end

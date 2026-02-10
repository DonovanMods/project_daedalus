# frozen_string_literal: true

require "rails_helper"

RSpec.describe "mods/show.html.erb", type: :view do
  let(:mod) do
    build(:mod,
          name: "Test Mod",
          author: "Test Author",
          description: "Test description",
          files: { pak: "https://example.com/test.pak" },
          metadata: { status: {} })
  end

  before do
    assign(:mod, mod)
    allow(view).to receive(:session).and_return({ origin_url: "/mods" })
  end

  it "renders without errors" do
    expect { render }.not_to raise_error
  end

  it "includes analytics button with correct path" do
    render

    # Check that the rendered HTML contains the expected path components
    expect(rendered).to include(mod.author_slug)
    expect(rendered).to include(mod.slug)
    expect(rendered).to include("analytics=true")
  end

  it "analytics button path includes both author and slug" do
    render

    doc = Nokogiri::HTML(rendered)
    analytics_buttons = doc.css("button").select { |btn| btn.text.include?("Analytics") }

    expect(analytics_buttons).not_to be_empty

    analytics_button = analytics_buttons.first
    path = analytics_button["data-mods-path-param"]

    expect(path).to include(mod.author_slug)
    expect(path).to include(mod.slug)
    expect(path).to include("analytics=true")
  end

  context "with nil metadata" do
    let(:mod) do
      build(:mod,
            name: "Nil Meta Mod",
            author: "Author",
            description: "A mod with no metadata",
            files: { pak: "https://example.com/test.pak" },
            metadata: nil)
    end

    before do
      assign(:mod, mod)
      allow(view).to receive(:session).and_return({ origin_url: "/mods" })
      allow(view).to receive(:params).and_return({ analytics: "true" })
    end

    it "renders without error when metadata is nil and analytics requested" do
      expect { render }.not_to raise_error
    end

    it "does not render analytics partial when metadata is nil" do
      render
      expect(rendered).not_to include("No analytics data available")
      expect(rendered).not_to include("All Clear")
    end
  end
end

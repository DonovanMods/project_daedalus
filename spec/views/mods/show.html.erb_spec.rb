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
    assign(:all_mods, [mod])
    allow(view).to receive(:session).and_return({ origin_url: "/mods" })
  end

  it "renders without errors" do
    expect { render }.not_to raise_error
  end

  it "includes collapsible analytics section" do
    render

    doc = Nokogiri::HTML(rendered)
    details = doc.css("details")
    expect(details).not_to be_empty

    summary = details.first.css("summary")
    expect(summary.text).to include("Analytics")
  end

  it "renders the analytics partial inside the dropdown" do
    render
    expect(rendered).to include("Analytics")
    expect(rendered).to include("Mod Status")
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
      assign(:all_mods, [mod])
      allow(view).to receive(:session).and_return({ origin_url: "/mods" })
    end

    it "renders without error when metadata is nil" do
      expect { render }.not_to raise_error
    end

    it "shows no analytics data message when metadata is nil" do
      render
      expect(rendered).to include("No analytics data available")
      expect(rendered).not_to include("All Clear")
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe "mods/show.html.erb", type: :view do
  let(:mod) {
    build(:mod,
      name: "Test Mod",
      author: "Test Author",
      description: "Test description",
      files: {pak: "https://example.com/test.pak"},
      metadata: {status: {}})
  }

  before do
    assign(:mod, mod)
    allow(view).to receive(:session).and_return({origin_url: "/mods"})
  end

  it "renders without errors" do
    expect { render }.not_to raise_error
  end

  it "includes analytics button with correct path" do
    render

    expect(rendered).to have_selector(
      "button[data-mods-path-param*='#{mod.author_slug}']"
    )
    expect(rendered).to have_selector(
      "button[data-mods-path-param*='#{mod.slug}']"
    )
    expect(rendered).to have_selector(
      "button[data-mods-path-param*='analytics=true']"
    )
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
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe "mods/_mods.html.erb", type: :view do
  let(:mod1) { build(:mod, name: "Mod One", author: "Author A", version: "1.0", compatibility: "w1", description: "First mod") }
  let(:mod2) { build(:mod, name: "Mod Two", author: "Author B", version: "2.0", compatibility: "w2", description: "Second mod") }

  before do
    assign(:total_mods, 2)
  end

  context "with mods present" do
    it "wraps content in turbo_frame_tag with id='mods'" do
      render partial: "mods/mods", locals: {mods: [mod1, mod2]}
      expect(rendered).to include('<turbo-frame id="mods">')
    end

    it "displays total mod count" do
      render partial: "mods/mods", locals: {mods: [mod1, mod2]}
      expect(rendered).to include("2 mods displayed")
    end

    it "renders table with correct headers" do
      render partial: "mods/mods", locals: {mods: [mod1, mod2]}
      expect(rendered).to include("Name")
      expect(rendered).to include("Author")
      expect(rendered).to include("Version")
      expect(rendered).to include("Week")
      expect(rendered).to include("Description")
    end

    it "renders each mod using _mod partial" do
      render partial: "mods/mods", locals: {mods: [mod1, mod2]}
      expect(rendered).to include("Mod One")
      expect(rendered).to include("Mod Two")
    end

    it "has responsive table classes for different screen sizes" do
      render partial: "mods/mods", locals: {mods: [mod1, mod2]}
      expect(rendered).to include("sm:table-cell")
      expect(rendered).to include("xl:table-cell")
      expect(rendered).to include("lg:table-cell")
    end
  end

  context "with empty mods array" do
    before do
      assign(:total_mods, 0)
    end

    it "displays 'No mods found' message" do
      render partial: "mods/mods", locals: {mods: []}
      expect(rendered).to include("No mods match your query")
    end

    it "shows message in table row with proper colspan" do
      render partial: "mods/mods", locals: {mods: []}
      expect(rendered).to include('colspan="6"')
    end

    it "still displays mod count as 0" do
      render partial: "mods/mods", locals: {mods: []}
      expect(rendered).to include("0 mods displayed")
    end
  end
end

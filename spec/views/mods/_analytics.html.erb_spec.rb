# frozen_string_literal: true

require "rails_helper"

RSpec.describe "mods/_analytics.html.erb", type: :view do
  context "with errors and warnings" do
    it "renders errors in red" do
      metadata = { errors: ["Missing pak file"], warnings: [] }
      render partial: "mods/analytics", locals: { metadata: metadata }
      expect(rendered).to include("text-red-500")
      expect(rendered).to include("Missing pak file")
    end

    it "renders warnings in yellow" do
      metadata = { errors: [], warnings: ["Outdated version"] }
      render partial: "mods/analytics", locals: { metadata: metadata }
      expect(rendered).to include("text-yellow-500")
      expect(rendered).to include("Outdated version")
    end
  end

  context "with no issues" do
    it "shows All Clear" do
      metadata = { errors: [], warnings: [] }
      render partial: "mods/analytics", locals: { metadata: metadata }
      expect(rendered).to include("All Clear")
    end
  end

  context "with nil metadata" do
    it "handles nil gracefully" do
      expect {
        render partial: "mods/analytics", locals: { metadata: nil }
      }.not_to raise_error
      expect(rendered).to include("No analytics data available")
    end
  end

  context "with missing keys" do
    it "handles metadata without errors key" do
      expect {
        render partial: "mods/analytics", locals: { metadata: { warnings: ["test"] } }
      }.not_to raise_error
    end

    it "handles metadata without warnings key" do
      expect {
        render partial: "mods/analytics", locals: { metadata: { errors: ["test"] } }
      }.not_to raise_error
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Mods" do
  describe "GET /mods" do
    it "returns http success" do
      get "/mods"

      expect(response).to have_http_status(:success)
    end
  end
end

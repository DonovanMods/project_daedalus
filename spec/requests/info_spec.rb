# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Info" do
  describe "GET /info" do
    it "returns http success" do
      get "/info"

      expect(response).to have_http_status(:success)
    end
  end
end

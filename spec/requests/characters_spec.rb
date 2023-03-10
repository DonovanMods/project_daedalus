# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Characters" do
  describe "GET /characters" do
    it "returns http success" do
      get "/characters"

      expect(response).to have_http_status(:success)
    end
  end
end

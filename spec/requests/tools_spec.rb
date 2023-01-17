# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Tools" do
  describe "GET /tools" do
    it "returns http success" do
      get "/tools"
      expect(response).to have_http_status(:success)
    end
  end
end

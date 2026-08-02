# frozen_string_literal: true

require "rails_helper"

RSpec.describe "HealthCheck" do
  describe "GET /up" do
    it "returns http success" do
      get "/up"

      expect(response).to have_http_status(:success)
    end
  end
end

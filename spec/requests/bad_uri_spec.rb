# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Bad URI requests", type: :request do
  describe "GET with malformed URI" do
    it "returns 400 for bad percent-encoding" do
      get "/mods/%E0%A0"

      expect(response).to have_http_status(:bad_request)
    end
  end
end

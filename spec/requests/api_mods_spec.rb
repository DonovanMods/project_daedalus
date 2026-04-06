# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API Mods" do
  let(:mods) { build_list(:mod, 3) }

  before do
    allow(Mod).to receive(:all).and_return(mods)
  end

  describe "GET /api/mods" do
    it "returns http success" do
      get "/api/mods"

      expect(response).to have_http_status(:success)
    end

    it "returns JSON content type" do
      get "/api/mods"

      expect(response.content_type).to include("application/json")
    end

    it "returns the correct mod count" do
      get "/api/mods"

      json = JSON.parse(response.body)
      expect(json["count"]).to eq(3)
      expect(json["mods"].size).to eq(3)
    end

    it "includes required fields for each mod" do
      get "/api/mods"

      json = JSON.parse(response.body)
      mod_json = json["mods"].first

      %w[id name author author_slug slug version description file_types url created_at updated_at].each do |field|
        expect(mod_json).to have_key(field), "missing field: #{field}"
      end
    end

    it "includes updated_at timestamp in response root" do
      get "/api/mods"

      json = JSON.parse(response.body)
      expect(json).to have_key("updated_at")
    end

    it "sets CORS headers" do
      get "/api/mods"

      expect(response.headers["Access-Control-Allow-Origin"]).to eq("*")
      expect(response.headers["Access-Control-Allow-Methods"]).to eq("GET")
    end

    it "sets cache headers" do
      get "/api/mods"

      expect(response.headers["Cache-Control"]).to include("public")
    end

    it "truncates long descriptions" do
      long_desc_mod = build(:mod, description: "A" * 1000)
      allow(Mod).to receive(:all).and_return([long_desc_mod])

      get "/api/mods"

      json = JSON.parse(response.body)
      expect(json["mods"].first["description"].length).to be <= 500
    end

    it "returns 503 when Firestore is unavailable" do
      allow(Mod).to receive(:all).and_raise(StandardError, "Firestore connection failed")
      Rails.cache.delete("api/mods.json")

      get "/api/mods"

      expect(response).to have_http_status(:service_unavailable)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("Service temporarily unavailable")
    end
  end
end

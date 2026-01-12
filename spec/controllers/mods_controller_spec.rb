# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Mods Search", type: :request do
  let(:mod1) { build(:mod, name: "Super Mod", author: "John", compatibility: "w1", description: "A great mod") }
  let(:mod2) { build(:mod, name: "Test Mod", author: "Jane", compatibility: nil, description: "Test description") }
  let(:mod3) { build(:mod, name: "Another", author: "Bob", compatibility: "w2", description: "Something") }

  before do
    allow(Mod).to receive(:all).and_return([mod1, mod2, mod3])
  end

  describe "GET /mods with search query" do
    context "with valid search terms" do
      it "finds mods by name" do
        get "/mods", params: { query: "Super" }
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Super Mod")
        expect(response.body).not_to include("Test Mod")
      end

      it "finds mods by author" do
        get "/mods", params: { query: "Jane" }
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Jane")
      end

      it "finds mods by compatibility" do
        get "/mods", params: { query: "w2" }
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Another")
      end

      it "finds mods by description" do
        get "/mods", params: { query: "great" }
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Super Mod")
      end
    end

    context "with nil compatibility values" do
      it "does not crash when searching and compatibility is nil" do
        expect do
          get "/mods", params: { query: "Test" }
        end.not_to raise_error
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Test Mod")
      end
    end

    context "with regex special characters" do
      it "escapes regex metacharacters in search" do
        # This should search literally for "(test)" not use it as a regex group
        expect do
          get "/mods", params: { query: "(test)" }
        end.not_to raise_error
        expect(response).to have_http_status(:success)
      end

      it "escapes dots in search" do
        expect do
          get "/mods", params: { query: "..." }
        end.not_to raise_error
        expect(response).to have_http_status(:success)
      end

      it "escapes asterisks in search" do
        expect do
          get "/mods", params: { query: "test*" }
        end.not_to raise_error
        expect(response).to have_http_status(:success)
      end

      it "prevents ReDoS attacks with catastrophic backtracking patterns" do
        # Pattern like (a+)+ can cause exponential backtracking
        malicious_pattern = "#{"a" * 50}!"
        expect do
          Timeout.timeout(1) do
            get "/mods", params: { query: malicious_pattern }
          end
        end.not_to raise_error
        expect(response).to have_http_status(:success)
      end
    end

    context "with empty or nil query" do
      it "returns all mods when query is empty" do
        get "/mods", params: { query: "" }
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Super Mod")
        expect(response.body).to include("Test Mod")
        expect(response.body).to include("Another")
      end
    end
  end

  describe "GET /mods with author filter" do
    it "finds mods by author slug" do
      get "/mods/#{mod1.author_slug}"
      expect(response).to have_http_status(:success)
      expect(response.body).to include(mod1.name)
    end
  end
end

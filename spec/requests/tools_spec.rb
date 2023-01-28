require "rails_helper"

RSpec.describe "Tools" do
  describe "GET /index" do
    it "returns http success" do
      get "/tools/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/tools/show"
      expect(response).to have_http_status(:success)
    end
  end
end

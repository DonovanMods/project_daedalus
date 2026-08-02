# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Tools" do
  before do
    allow(Tool).to receive(:all).and_return([build(:tool)])
  end

  describe "GET /tools" do
    it "returns http success" do
      get "/tools"
      expect(response).to have_http_status(:success)
    end
  end
end

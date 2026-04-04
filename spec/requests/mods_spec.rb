# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Mods" do
  before do
    allow(Mod).to receive(:all).and_return([build(:mod)])
  end

  describe "GET /mods" do
    it "returns http success" do
      get "/mods"

      expect(response).to have_http_status(:success)
    end
  end
end

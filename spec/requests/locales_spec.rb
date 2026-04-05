# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Locales", type: :request do
  describe "PATCH /locale" do
    it "sets locale cookie for a valid locale" do
      patch locale_path, params: { locale: "es" }

      expect(response).to redirect_to(root_path)
      expect(cookies[:locale]).to eq("es")
    end

    it "does not set cookie for an invalid locale" do
      patch locale_path, params: { locale: "xx" }

      expect(response).to redirect_to(root_path)
      expect(cookies[:locale]).to be_nil
    end

    it "redirects back to the referring page" do
      patch locale_path, params: { locale: "fr" }, headers: { "HTTP_REFERER" => mods_path }

      expect(response).to redirect_to(mods_path)
    end
  end
end

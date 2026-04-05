# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Locale detection", type: :request do
  describe "set_locale before_action" do
    it "defaults to English when no cookie or header is set" do
      get "/home"

      expect(response).to be_successful
      expect(response.body).to include("Welcome")
    end

    it "uses locale from cookie when present" do
      cookies[:locale] = "de"

      get "/home"

      expect(response).to be_successful
      expect(response.body).to include("Willkommen")
    end

    it "uses locale from Accept-Language header when no cookie" do
      get "/home", headers: { "HTTP_ACCEPT_LANGUAGE" => "es-ES,es;q=0.9,en;q=0.8" }

      expect(response).to be_successful
      expect(response.body).to include("Bienvenido")
    end

    it "ignores unsupported locales in Accept-Language header" do
      get "/home", headers: { "HTTP_ACCEPT_LANGUAGE" => "xx;q=0.9" }

      expect(response).to be_successful
    end

    it "cookie takes priority over Accept-Language header" do
      cookies[:locale] = "fr"

      get "/home", headers: { "HTTP_ACCEPT_LANGUAGE" => "de-DE,de;q=0.9" }

      expect(response).to be_successful
      expect(response.body).to include("Bienvenue")
    end
  end
end

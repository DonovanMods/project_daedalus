# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Locale detection", type: :request do
  describe "set_locale before_action" do
    it "defaults to English when no cookie or header is set" do
      get root_path

      expect(response).to be_successful
    end

    it "uses locale from cookie when present" do
      cookies[:locale] = "de"

      get root_path

      expect(response.body).to include("Willkommen")
    end

    it "uses locale from Accept-Language header when no cookie" do
      get root_path, headers: { "HTTP_ACCEPT_LANGUAGE" => "es-ES,es;q=0.9,en;q=0.8" }

      expect(response.body).to include("Mods de Icarus")
    end

    it "ignores unsupported locales in Accept-Language header" do
      get root_path, headers: { "HTTP_ACCEPT_LANGUAGE" => "xx;q=0.9" }

      expect(response).to be_successful
    end

    it "cookie takes priority over Accept-Language header" do
      cookies[:locale] = "fr"

      get root_path, headers: { "HTTP_ACCEPT_LANGUAGE" => "de-DE,de;q=0.9" }

      expect(response.body).to include("Bienvenue")
    end
  end
end

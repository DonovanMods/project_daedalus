# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Locale detection", type: :request do
  describe "set_locale before_action" do
    it "defaults to English when no cookie or header is set" do
      get "/home"

      expect(response).to be_successful
      expect(response.body).to match(/<html[^>]*lang="en"/)
    end

    it "falls back to English for unsupported locale in cookie" do
      cookies[:locale] = "xx"

      get "/home"

      expect(response).to be_successful
      expect(response.body).to match(/<html[^>]*lang="en"/)
    end

    it "ignores unsupported locales in Accept-Language header" do
      get "/home", headers: { "HTTP_ACCEPT_LANGUAGE" => "xx;q=0.9" }

      expect(response).to be_successful
      expect(response.body).to match(/<html[^>]*lang="en"/)
    end

    it "uses English for Accept-Language header with en" do
      get "/home", headers: { "HTTP_ACCEPT_LANGUAGE" => "en-US,en;q=0.9" }

      expect(response).to be_successful
      expect(response.body).to match(/<html[^>]*lang="en"/)
    end

    it "handles plain language tags without region or q-value" do
      get "/home", headers: { "HTTP_ACCEPT_LANGUAGE" => "en" }

      expect(response).to be_successful
      expect(response.body).to match(/<html[^>]*lang="en"/)
    end

    it "falls back to default when all Accept-Language locales are unsupported" do
      get "/home", headers: { "HTTP_ACCEPT_LANGUAGE" => "zz-ZZ,yy;q=0.9" }

      expect(response).to be_successful
      expect(response.body).to match(/<html[^>]*lang="en"/)
    end
  end
end

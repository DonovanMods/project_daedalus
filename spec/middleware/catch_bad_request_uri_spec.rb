# frozen_string_literal: true

require "rails_helper"

RSpec.describe CatchBadRequestUri do
  let(:app) { ->(env) { [200, {"content-type" => "text/plain"}, ["OK"]] } }
  let(:middleware) { described_class.new(app) }

  describe "#call" do
    context "with a valid request URI" do
      it "passes through to the app" do
        env = Rack::MockRequest.env_for("/mods")
        status, _headers, body = middleware.call(env)

        expect(status).to eq(200)
        expect(body).to eq(["OK"])
      end

      it "handles encoded characters in the path" do
        env = Rack::MockRequest.env_for("/mods/donovan-young/some-mod")
        status, _headers, _body = middleware.call(env)

        expect(status).to eq(200)
      end

      it "handles valid query strings" do
        env = Rack::MockRequest.env_for("/mods?query=test&sort=name")
        status, _headers, _body = middleware.call(env)

        expect(status).to eq(200)
      end
    end

    context "with an invalid request URI" do
      it "returns 400 for bad percent-encoding in path" do
        env = Rack::MockRequest.env_for("/")
        env["PATH_INFO"] = "/%E0%A0"
        status, headers, body = middleware.call(env)

        expect(status).to eq(400)
        expect(headers["content-type"]).to eq("text/plain")
        expect(body).to eq(["Bad Request"])
      end

      it "returns 400 for bad percent-encoding in query string" do
        env = Rack::MockRequest.env_for("/mods")
        env["QUERY_STRING"] = "q=%E0%A0"
        status, _headers, body = middleware.call(env)

        expect(status).to eq(400)
        expect(body).to eq(["Bad Request"])
      end

      it "returns 400 for incomplete percent-encoding" do
        env = Rack::MockRequest.env_for("/")
        env["PATH_INFO"] = "/mods/%"
        status, _headers, _body = middleware.call(env)

        expect(status).to eq(400)
      end
    end
  end
end

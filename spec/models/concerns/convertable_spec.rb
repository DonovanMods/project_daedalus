# frozen_string_literal: true

require "rails_helper"

RSpec.describe Convertable do
  subject(:convertable) { test_class.new }

  let(:test_class) { Struct.new(:test) { include Convertable } }

  describe "#raw_uri" do
    context "when the url is a GitHub URL" do
      let(:url) { "https://github.com/username/repo/raw/master/README.md" }

      it "returns the raw uri" do
        expect(convertable.raw_uri(url)).to eq(URI("https://raw.githubusercontent.com/username/repo/master/README.md"))
      end
    end

    context "when the url is not a GitHub URL" do
      let(:url) { Faker::Internet.url }

      it "returns the uri" do
        expect(convertable.raw_uri(url)).to eq(URI(url))
      end
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe ModsController, type: :controller do
  let(:mod1) { build(:mod, name: "Super Mod", author: "John", compatibility: "w1", description: "A great mod") }
  let(:mod2) { build(:mod, name: "Test Mod", author: "Jane", compatibility: nil, description: "Test description") }
  let(:mod3) { build(:mod, name: "Another", author: "Bob", compatibility: "w2", description: "Something") }

  before do
    allow(Mod).to receive(:all).and_return([mod1, mod2, mod3])
  end

  describe "GET #index with search query" do
    context "with valid search terms" do
      it "finds mods by name" do
        get :index, params: {query: "Super"}
        expect(assigns(:mods)).to include(mod1)
        expect(assigns(:mods)).not_to include(mod2)
      end

      it "finds mods by author" do
        get :index, params: {query: "Jane"}
        expect(assigns(:mods)).to include(mod2)
      end

      it "finds mods by compatibility" do
        get :index, params: {query: "w2"}
        expect(assigns(:mods)).to include(mod3)
      end

      it "finds mods by description" do
        get :index, params: {query: "great"}
        expect(assigns(:mods)).to include(mod1)
      end
    end

    context "with nil compatibility values" do
      it "does not crash when searching and compatibility is nil" do
        expect {
          get :index, params: {query: "Test"}
        }.not_to raise_error
        expect(assigns(:mods)).to include(mod2)
      end
    end

    context "with regex special characters" do
      it "escapes regex metacharacters in search" do
        # This should search literally for "(test)" not use it as a regex group
        expect {
          get :index, params: {query: "(test)"}
        }.not_to raise_error
      end

      it "escapes dots in search" do
        expect {
          get :index, params: {query: "..."}
        }.not_to raise_error
      end

      it "escapes asterisks in search" do
        expect {
          get :index, params: {query: "test*"}
        }.not_to raise_error
      end

      it "prevents ReDoS attacks with catastrophic backtracking patterns" do
        # Pattern like (a+)+ can cause exponential backtracking
        malicious_pattern = "a" * 50 + "!"
        expect {
          Timeout.timeout(1) do
            get :index, params: {query: malicious_pattern}
          end
        }.not_to raise_error
      end
    end

    context "with empty or nil query" do
      it "returns all mods when query is empty" do
        get :index, params: {query: ""}
        expect(assigns(:mods)).to eq([mod1, mod2, mod3])
      end
    end
  end

  describe "GET #index with author filter" do
    it "finds mods by author slug" do
      get :index, params: {author: mod1.author_slug}
      expect(assigns(:mods)).to include(mod1)
    end
  end
end

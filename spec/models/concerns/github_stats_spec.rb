# frozen_string_literal: true

require "rails_helper"

RSpec.describe GithubStats do
  subject(:mod) { test_class.new(readme_url: readme_url, files: files) }

  let(:test_class) do
    Struct.new(:readme_url, :files, keyword_init: true) do
      include GithubStats
    end
  end

  describe "#github_repo" do
    context "with a GitHub readme URL" do
      let(:readme_url) { "https://github.com/JimK72/Icarus-Mod-Manager/blob/main/README.md" }
      let(:files) { {} }

      it "extracts owner/repo" do
        expect(mod.github_repo).to eq("JimK72/Icarus-Mod-Manager")
      end
    end

    context "with a raw.githubusercontent URL in files" do
      let(:readme_url) { nil }
      let(:files) { { exmodz: "https://raw.githubusercontent.com/JimK72/Icarus-Mod-Manager/main/mod.exmodz" } }

      it "extracts owner/repo from file URL" do
        expect(mod.github_repo).to eq("JimK72/Icarus-Mod-Manager")
      end
    end

    context "with no GitHub URLs" do
      let(:readme_url) { nil }
      let(:files) { { pak: "https://example.com/mod.pak" } }

      it "returns nil" do
        expect(mod.github_repo).to be_nil
      end
    end

    context "with a .git suffix" do
      let(:readme_url) { "https://github.com/JimK72/Icarus-Mod-Manager.git" }
      let(:files) { {} }

      it "strips the .git suffix" do
        expect(mod.github_repo).to eq("JimK72/Icarus-Mod-Manager")
      end
    end
  end

  describe "#github_repo?" do
    let(:readme_url) { "https://github.com/JimK72/Icarus-Mod-Manager" }
    let(:files) { {} }

    it "returns true when a repo is detected" do
      expect(mod.github_repo?).to be true
    end
  end

  describe "#github_data" do
    let(:readme_url) { nil }
    let(:files) { {} }

    it "returns nil when no repo is detected" do
      expect(mod.github_data).to be_nil
    end
  end
end

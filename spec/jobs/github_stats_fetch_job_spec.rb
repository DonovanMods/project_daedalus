# frozen_string_literal: true

require "rails_helper"

RSpec.describe GithubStatsFetchJob do
  let(:repo) { "JimK72/Icarus-Mod-Manager" }
  let(:cache_key) { "github/#{repo}" }
  let(:job) { described_class.new }

  before { Rails.cache.clear }

  def stub_http(response)
    allow(Net::HTTP).to receive(:start).and_yield(double(request: response))
  end

  describe "#perform" do
    context "with a successful API response" do
      let(:body) do
        {
          stargazers_count: 42,
          forks_count: 7,
          open_issues_count: 3,
          pushed_at: "2026-01-01T00:00:00Z",
          description: "A mod manager",
          license: { spdx_id: "MIT" },
          html_url: "https://github.com/#{repo}"
        }.to_json
      end

      before do
        response = instance_double(Net::HTTPSuccess, body: body, is_a?: false)
        allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
        stub_http(response)
      end

      it "writes the parsed result to the cache" do
        job.perform(repo)

        cached = Rails.cache.read(cache_key)
        expect(cached).to include(
          stars: 42,
          forks: 7,
          open_issues: 3,
          description: "A mod manager",
          license: "MIT",
          repo_url: "https://github.com/#{repo}"
        )
      end
    end

    context "with a non-success response" do
      before do
        response = instance_double(Net::HTTPNotFound, is_a?: false)
        allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)
        stub_http(response)
      end

      it "caches :unavailable" do
        job.perform(repo)
        expect(Rails.cache.read(cache_key)).to eq(:unavailable)
      end
    end

    context "when the request raises" do
      before do
        allow(Net::HTTP).to receive(:start).and_raise(Errno::ECONNREFUSED)
      end

      it "caches :unavailable and does not propagate" do
        expect { job.perform(repo) }.not_to raise_error
        expect(Rails.cache.read(cache_key)).to eq(:unavailable)
      end
    end

    context "with an invalid repo string" do
      it "is a no-op for path-traversal-shaped input" do
        expect(Net::HTTP).not_to receive(:start)
        job.perform("../../etc/passwd")
      end

      it "is a no-op for nil input" do
        expect(Net::HTTP).not_to receive(:start)
        job.perform(nil)
      end
    end
  end
end

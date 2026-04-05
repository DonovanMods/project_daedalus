# frozen_string_literal: true

require "net/http"

module GithubStats
  extend ActiveSupport::Concern

  # Extracts the GitHub owner/repo from any GitHub URL associated with this mod
  # Checks readme_url first, then file URLs
  def github_repo
    @github_repo ||= extract_github_repo
  end

  def github_repo?
    github_repo.present?
  end

  # Fetches repository stats from the GitHub API (cached per mod)
  def github_data
    return nil unless github_repo?

    @github_data ||= fetch_github_data
  end

  private

  def extract_github_repo
    urls = [readme_url, *files.values].compact
    urls.each do |url|
      match = url.to_s.match(%r{github\.com/([^/]+)/([^/]+)}i) ||
              url.to_s.match(%r{raw\.githubusercontent\.com/([^/]+)/([^/]+)}i)
      return "#{match[1]}/#{match[2].sub(/\.git$/, "")}" if match
    end
    nil
  end

  def fetch_github_data
    Rails.cache.fetch("github/#{github_repo}", expires_in: 15.minutes) do
      fetch_github_api
    end
  end

  def fetch_github_api
    response = github_http_request
    return nil unless response.is_a?(Net::HTTPSuccess)

    parse_github_response(response.body)
  rescue StandardError => e
    Rails.logger.error("Failed to fetch GitHub stats for #{github_repo}: #{e.class} - #{e.message}")
    nil
  end

  def github_http_request
    uri = URI("https://api.github.com/repos/#{github_repo}")
    request = Net::HTTP::Get.new(uri)
    request["Accept"] = "application/vnd.github.v3+json"
    request["User-Agent"] = "ProjectDaedalus"

    Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 5) do |http|
      http.request(request)
    end
  end

  def parse_github_response(body)
    data = JSON.parse(body, symbolize_names: true)
    {
      stars: data[:stargazers_count] || 0,
      forks: data[:forks_count] || 0,
      open_issues: data[:open_issues_count] || 0,
      last_push: data[:pushed_at]&.then { |t| Time.zone.parse(t) },
      description: data[:description],
      license: data.dig(:license, :spdx_id),
      repo_url: data[:html_url]
    }
  end
end

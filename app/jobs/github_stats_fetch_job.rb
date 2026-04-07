# frozen_string_literal: true

require "net/http"

# Background job that fetches repository metadata from the GitHub API and
# writes the result to Rails.cache. Replaces the previous Thread.new approach
# in GithubStats so that fetches are managed by the application's job runner
# (Solid Queue in production) instead of unbounded raw threads.
class GithubStatsFetchJob < ApplicationJob
  queue_as :default

  # Match GithubStats#extract_github_repo — only allow safe owner/repo characters.
  REPO_FORMAT = %r{\A[\w.-]+/[\w.-]+\z}

  def perform(repo)
    return unless repo.is_a?(String) && repo.match?(REPO_FORMAT)

    cache_key = "github/#{repo}"
    result = fetch_github_api(repo)

    if result
      Rails.cache.write(cache_key, result, expires_in: 15.minutes)
    else
      Rails.cache.write(cache_key, :unavailable, expires_in: 5.minutes)
    end
  rescue StandardError => e
    Rails.logger.error("GithubStatsFetchJob failed for #{repo}: #{e.class} - #{e.message}")
    Rails.cache.write("github/#{repo}", :unavailable, expires_in: 5.minutes)
  end

  private

  def fetch_github_api(repo)
    uri = URI("https://api.github.com/repos/#{repo}")
    request = Net::HTTP::Get.new(uri)
    request["Accept"] = "application/vnd.github.v3+json"
    request["User-Agent"] = "ProjectDaedalus"

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 5) do |http|
      http.request(request)
    end

    return nil unless response.is_a?(Net::HTTPSuccess)

    parse_github_response(response.body)
  rescue StandardError => e
    Rails.logger.error("Failed to fetch GitHub stats for #{repo}: #{e.class} - #{e.message}")
    nil
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

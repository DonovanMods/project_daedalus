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

  # Returns cached repository stats. Never blocks the request thread.
  # On cache miss, returns nil and triggers a background fetch so data
  # is available on the next page load.
  def github_data
    return nil unless github_repo?

    cache_key = "github/#{github_repo}"
    cached = Rails.cache.read(cache_key)

    if cached && %i[unavailable fetching].exclude?(cached)
      cached
    elsif cached.nil?
      # No cache entry — schedule background fetch so next request has data
      fetch_github_data_async
      nil
    else
      # :fetching or :unavailable — wait for TTL to expire
      nil
    end
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

  # Non-blocking: spawns a thread to fetch and cache GitHub data.
  # Writes a :fetching sentinel first to prevent dogpile (multiple
  # concurrent requests spawning duplicate threads for the same repo).
  # On failure, caches :unavailable to throttle retries.
  def fetch_github_data_async
    repo = github_repo
    cache_key = "github/#{repo}"

    # Claim this fetch — prevents other requests from spawning duplicate threads
    Rails.cache.write(cache_key, :fetching, expires_in: 2.minutes)

    Thread.new do
      Rails.application.executor.wrap do
        result = fetch_github_api(repo)
        if result
          Rails.cache.write(cache_key, result, expires_in: 15.minutes)
        else
          Rails.cache.write(cache_key, :unavailable, expires_in: 5.minutes)
        end
      end
    rescue StandardError => e
      Rails.logger.error("Background GitHub fetch failed for #{repo}: #{e.class} - #{e.message}")
      Rails.cache.write(cache_key, :unavailable, expires_in: 5.minutes)
    end
  end

  def fetch_github_api(repo = github_repo)
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

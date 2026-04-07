# frozen_string_literal: true

module GithubStats
  extend ActiveSupport::Concern

  # Restrict owner/repo characters to GitHub-legal values to prevent malformed
  # URL injection (path traversal, querystring smuggling, etc.).
  GITHUB_SEGMENT = %r{[\w.-]+}

  # Extracts the GitHub owner/repo from any GitHub URL associated with this mod
  # Checks readme_url first, then file URLs
  def github_repo
    @github_repo ||= extract_github_repo
  end

  def github_repo?
    github_repo.present?
  end

  # Returns cached repository stats. Never blocks the request thread.
  # On cache miss, returns nil and enqueues a background job so data
  # is available on the next page load.
  def github_data
    return nil unless github_repo?

    cache_key = "github/#{github_repo}"
    cached = Rails.cache.read(cache_key)

    if cached && %i[unavailable fetching].exclude?(cached)
      cached
    elsif cached.nil?
      # No cache entry — enqueue background fetch so next request has data
      enqueue_github_fetch
      nil
    end
    # :fetching or :unavailable — implicitly returns nil, waits for TTL to expire
  end

  private

  def extract_github_repo
    urls = [readme_url, *files.values].compact
    pattern = %r{(?:github\.com|raw\.githubusercontent\.com)/(#{GITHUB_SEGMENT})/(#{GITHUB_SEGMENT})}i
    urls.each do |url|
      match = url.to_s.match(pattern)
      return "#{match[1]}/#{match[2].sub(/\.git$/, "")}" if match
    end
    nil
  end

  # Enqueues a background job to fetch GitHub data. Writes a :fetching sentinel
  # first to prevent dogpile (multiple concurrent requests enqueueing duplicate
  # jobs for the same repo). On failure, the job caches :unavailable.
  def enqueue_github_fetch
    repo = github_repo
    cache_key = "github/#{repo}"

    # Claim this fetch — prevents other requests from enqueueing duplicate jobs
    Rails.cache.write(cache_key, :fetching, expires_in: 2.minutes)
    GithubStatsFetchJob.perform_later(repo)
  end
end

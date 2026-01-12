# frozen_string_literal: true

require "net/http"

class Tool
  include ActiveModel::Model
  include Convertable
  include Firestorable

  SORTKEYS = %w[author name].freeze
  ATTRIBUTES = %i[id name author version compatibility description file_type url image_url readme_url created_at updated_at].freeze

  ATTRIBUTES.each { |attr| attr_accessor attr }

  def self.all
    firestore.col("tools").get.filter_map do |tool|
      new(
        id: tool.document_id,
        name: tool.data[:name],
        author: tool.data[:author],
        description: tool.data[:description],
        version: tool.data[:version],
        compatibility: tool.data[:compatibility],
        file_type: tool.data[:fileType],
        url: tool.data[:fileURL],
        image_url: tool.data[:imageURL],
        readme_url: tool.data[:readmeURL],
        created_at: tool.create_time,
        updated_at: tool.update_time
      )
    end.sort_by(&:name)
  end

  def readme
    return @readme if defined?(@readme)

    @readme = readme_url.present? ? fetch_readme : nil
    @readme
  end

  def details
    return readme if readme.present?

    description
  end

  def filename
    url.split("/").last
  end

  def name_slug
    name.parameterize
  end

  def author_slug
    author.parameterize
  end

  def slug
    "#{author_slug}-#{name_slug}"
  end

  def updated_string
    "Last Updated on #{updated_at.strftime("%B %d, %Y")}"
  end

  def version_string
    v = []
    v << "v#{version}" if version.present?
    v << compatibility if compatibility.present?

    v.join(" / ")
  end

  private

  def fetch_readme
    # We strip out the first # line of the README, as it's usually a title
    Net::HTTP.get(raw_uri(readme_url)).gsub(/^#\s+.*$/, "").strip
  rescue SocketError, Errno::ECONNREFUSED, Timeout::Error,
         Net::HTTPError, URI::InvalidURIError, OpenSSL::SSL::SSLError => e
    Rails.logger.error("Failed to fetch README for tool '#{name}' from #{readme_url}: #{e.class} - #{e.message}")
    nil
  end
end

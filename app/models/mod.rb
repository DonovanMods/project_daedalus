# frozen_string_literal: true

require "net/http"

class Mod
  include ActiveModel::Model
  include Convertable
  include Firestorable

  SORTKEYS = %w[author name].freeze
  ATTRIBUTES = %i[author compatibility description files id image_url metadata name readme_url timestamps version
                  created_at updated_at].freeze

  ATTRIBUTES.each { |attr| attr_accessor attr }

  def self.all
    firestore.col("mods").get.filter_map do |mod|
      new(
        author: mod.data[:author],
        compatibility: mod.data[:compatibility],
        description: mod.data[:description],
        files: mod.data[:files] || {},
        id: mod.document_id,
        image_url: mod.data[:imageURL],
        metadata: mod.data[:meta],
        name: mod.data[:name],
        readme_url: mod.data[:readmeURL],
        version: mod.data[:version],
        created_at: mod.create_time,
        updated_at: mod.update_time
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

  def files?
    files.keys.any?
  end

  def pak?
    files.key?(:pak)
  end

  def zip?
    files.key?(:zip)
  end

  def exmodz?
    files.key?(:exmodz)
  end

  # Determins which file types can be downloaded from the index page
  def preferred_type
    return :pak if pak?

    :zip if zip?
  end

  # Determins which file types can be downloaded from the show page
  def download_types
    file_types.map(&:to_sym) & %i[pak zip exmodz]
  end

  def file_types
    files.keys
  end

  def urls
    files.values
  end

  def get_url(type)
    files[type.to_sym]
  end

  def get_name(type)
    filename(files[type.to_sym])
  end

  def types_string
    file_types.map(&:upcase).sort.join(" / ")
  end

  def author_slug
    author.parameterize
  end

  def slug
    name.parameterize
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
         Net::HTTPError, Net::HTTPClientException, URI::InvalidURIError, OpenSSL::SSL::SSLError => e
    Rails.logger.error("Failed to fetch README for mod '#{name}' from #{readme_url}: #{e.class} - #{e.message}")
    nil
  end

  def filename(url)
    return unless url

    URI(url).path.split("/").last
  end

  def exmod_type
    files.key?(:exmodz) ? :exmodz : :exmod
  end
end

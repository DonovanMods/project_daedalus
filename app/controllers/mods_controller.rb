# frozen_string_literal: true

class ModsController < ApplicationController
  include PaginationHelper

  before_action :authors, only: %i[index show]
  before_action :mods, only: %i[index show]
  before_action :set_session, only: %i[index]

  def index
    @filtered = false

    filter_by_author
    return if performed?

    filter_by_query
    @total_mods = @mods.size
    paginate_mods unless @filtered
    render_index
  end

  def show
    @mod = mods.find do |mod|
      mod.author_slug.casecmp(params[:author].parameterize)&.zero? && mod.slug.casecmp(params[:slug])&.zero?
    end

    return unless @mod.nil?

    flash[:error] = t("mod-not-found", author: params[:author], slug: params[:slug])

    return redirect_to mods_author_path(author: params[:author]) if params[:author].present?

    redirect_to mods_path
  end

  private

  def filter_by_author
    return if params[:author].blank?

    @mods = find_mods_by_author(sanitize(params[:author]))
    @filtered = true

    # If no mods found by author slug, try to find by mod ID and redirect
    return unless @mods.empty?

    @mod = mods.find { |mod| mod.id == params[:author] }
    redirect_to mod_detail_path(author: @mod.author_slug, slug: @mod.slug) if @mod.present?
  end

  def filter_by_query
    return if params[:query].blank?

    @mods = find_mods(sanitize(params[:query]))
    @filtered = true
  end

  def paginate_mods
    @pagination = paginate_array(@mods, page: params[:page])
    @mods = @pagination.items
  end

  def render_index
    if turbo_frame_request?
      render partial: "mods", locals: { mods: @mods }
    else
      render :index
    end
  end

  def find_mods(query)
    # Escape regex special characters to prevent injection
    escaped_query = Regexp.escape(query)
    pattern = /#{escaped_query}/i

    mods.find_all do |mod|
      mod.name.match?(pattern) ||
        mod.author.match?(pattern) ||
        mod.compatibility&.match?(pattern) ||
        mod.description.match?(pattern)
    end
  end

  def find_mods_by_author(author)
    mods.find_all { |mod| mod.author_slug.casecmp(author.parameterize).zero? }
  end

  def authors
    @authors ||= mods.map(&:author).uniq.sort
  end

  def mods
    @mods ||= combined_mods
  end

  # Merges curated mods (Firestore `mods`) with mods synced from the
  # Nexus API (Firestore `nexus_mods`). Curated mods take precedence
  # when a name+author match exists.
  def combined_mods
    (Mod.all + NexusMod.all)
      .uniq { |mod| [mod.name.to_s.downcase, mod.author_slug] }
      .sort_by { |mod| mod.name.to_s }
  end

  def set_session
    session[:origin_url] = request.original_url
  end
end

# frozen_string_literal: true

class ModsController < ApplicationController
  before_action :authors, only: %i[index show]
  before_action :mods, only: %i[index show]
  before_action :set_session, only: %i[index]

  def index
    @mods = find_mods_by_author(sanitize(params[:author])) if params[:author].present?

    # If we're given a mod ID, try to find it and redirect to the mod's page
    if @mods.empty? && params[:author].present?
      @mod = mods.find { |mod| mod.id == params[:author] }
      return redirect_to mod_detail_path(author: @mod.author_slug, slug: @mod.slug) if @mod.present?
    end

    # Perform a search if we have a query
    @mods = find_mods(sanitize(params[:query])) if params[:query].present?

    # Sort the mods if we have a sort key
    # Disabled for now, as it's redundant with the search
    # params[:sort].present? && Mod::SORTKEYS.include?(params[:sort]) && @mods.sort_by! { |mod| [mod.send(sanitize(params[:sort])), mod.name] }

    @total_mods = @mods.size

    if turbo_frame_request?
      render partial: "mods", locals: { mods: @mods }
    else
      render :index
    end
  end

  def show
    @mod = mods.find { |mod| mod.author_slug.casecmp(params[:author].parameterize)&.zero? && mod.slug.casecmp(params[:slug])&.zero? }

    return unless @mod.nil?

    flash[:error] = t("mod-not-found", author: params[:author], slug: params[:slug])

    return redirect_to mods_author_path(author: params[:author]) if params[:author].present?

    redirect_to mods_path
  end

  private

  def find_mods(query)
    mods.find_all do |mod|
      mod.name               =~ /#{query}/i ||
        mod.author           =~ /#{query}/i ||
        mod.compatibility    =~ /#{query}/i ||
        mod.description      =~ /#{query}/i
    end
  end

  def find_mods_by_author(author)
    mods.find_all { |mod| mod.author_slug.casecmp(author.parameterize).zero? }
  end

  def authors
    @authors ||= mods.map(&:author).uniq.sort
  end

  def mods
    @mods ||= Mod.all
  end

  def set_session
    session[:origin_url] = request.original_url
  end
end

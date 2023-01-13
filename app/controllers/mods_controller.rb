# frozen_string_literal: true

class ModsController < ApplicationController
  before_action :fetch_mods, only: %i[index show]

  def index
    @mods = find_mods(params[:query]) if params[:query].present?
    params[:sort].present? && Mod::SORTKEYS.include?(params[:sort]) && @mods.sort_by! { |mod| [mod.send(params[:sort]), mod.name] }

    if turbo_frame_request?
      render partial: "mods", locals: { mods: @mods }
    else
      render :index
    end
  end

  def show
    @mod = @mods.find { |mod| mod.id == params[:id] }
  end

  private

  def find_mods(query)
    @mods.find_all do |mod|
      mod.name =~ /#{query}/i ||
        mod.author =~ /#{query}/i ||
        mod.description =~ /#{query}/i ||
        mod.long_description =~ /#{query}/i
    end
  end

  def firestore
    @firestore ||= Firestore.new
  end

  def fetch_mods
    @mods = firestore.mods
  end
end

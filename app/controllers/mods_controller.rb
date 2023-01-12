# frozen_string_literal: true

class ModsController < ApplicationController
  before_action :fetch_mods, only: %i[index show]

  def index
    @mods.sort_by! { |mod| [mod.send(params[:sort]), mod.name] } if params.key?(:sort) && Mod::SORTKEYS.include?(params[:sort])
  end

  def show
    @mod = @mods.find { |mod| mod.id == params[:id] }
  end

  private

  def firestore
    @firestore ||= Firestore.new
  end

  def fetch_mods
    @mods = firestore.mods
  end
end

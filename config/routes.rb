# frozen_string_literal: true

Rails.application.routes.draw do
  get "home", to: "home#index"
  get "info", to: "info#index"

  scope :mods do
    get "/:author/:slug", to: "mods#show",  as: "mod_detail"
    get "/:author",       to: "mods#index", as: "mods_author"
    get "/",              to: "mods#index", as: "mods"
  end

  # Defines the root path route ("/")
  root "mods#index"
end

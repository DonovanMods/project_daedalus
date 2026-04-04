# frozen_string_literal: true

Rails.application.routes.draw do
  Healthcheck.routes(self)

  get "home", to: "home#index"
  get "info", to: "info#index"

  # Admin routes (session-based auth with ADMIN_PASSWORD)
  namespace :admin do
    get "login", to: "sessions#new", as: "login"
    post "login", to: "sessions#create"
    delete "logout", to: "sessions#destroy", as: "logout"
    get "info", to: "info#edit", as: "info_edit"
    patch "info", to: "info#update", as: "info_update"
    post "info/sections", to: "info#add_section", as: "info_add_section"
    delete "info/sections/:index", to: "info#remove_section", as: "info_remove_section"
  end

  scope :mods do
    get "/:author/:slug", to: "mods#show", as: "mod_detail"
    get "/:author", to: "mods#index", as: "mods_author"
    get "/", to: "mods#index", as: "mods"
  end

  scope :tools do
    # get "/:author/:slug", to: "tools#show",  as: "tool_detail"
    get "/:author", to: "tools#index", as: "tools_author"
    get "/", to: "tools#index", as: "tools"
  end

  # Defines the root path route ("/")
  root "mods#index"
end

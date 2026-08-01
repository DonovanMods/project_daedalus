# frozen_string_literal: true

Rails.application.routes.draw do
  # Can be used by load balancers and uptime monitors to verify that
  # the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  get "home", to: "home#index"
  get "info", to: "info#index"

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

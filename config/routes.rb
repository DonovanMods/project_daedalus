# frozen_string_literal: true

Rails.application.routes.draw do
  get "home", to: "home#index"

  get "mods", to: "mods#index", as: "mods"
  get "mods/:id", to: "mods#show", as: "mod"

  get "tools", to: "tools#index"

  # Defines the root path route ("/")
  root "mods#index"
end

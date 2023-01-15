# frozen_string_literal: true

Rails.application.routes.draw do
  # resources :mods
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  get "/mods", to: "mods#index", as: "mods"
  get "/mods/:id", to: "mods#show", as: "mod"

  get "/home", to: "home#index"

  # Defines the root path route ("/")
  root "mods#index"
end

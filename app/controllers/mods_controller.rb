# frozen_string_literal: true

require "google/cloud/firestore"
require "net/http"
require "uri"
require "json"

class ModsController < ApplicationController
  def index
    @mods = fetch_mods
  end

  private

  def fetch_mods
    client = Google::Cloud::Firestore.new(credentials: Rails.application.credentials.firebase_keyfile.to_h)
    client.col("mods").get
  end
end

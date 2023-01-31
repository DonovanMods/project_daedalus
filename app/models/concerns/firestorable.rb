# frozen_string_literal: true

require "google/cloud/firestore"

module Firestorable
  extend ActiveSupport::Concern

  included do
    def self.firestore
      Google::Cloud::Firestore.new(credentials: Rails.application.credentials.firebase_keyfile.to_h)
    end
  end
end

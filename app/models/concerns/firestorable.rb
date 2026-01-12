# frozen_string_literal: true

require "google/cloud/firestore"

module Firestorable
  extend ActiveSupport::Concern

  included do
    def self.firestore
      credentials = Rails.application.credentials.firebase_keyfile

      if credentials.nil?
        raise <<~ERROR
          Firebase credentials not configured. Please add firebase_keyfile to your Rails credentials.

          To configure credentials, run:
            EDITOR=nano rails credentials:edit

          Then add:
            firebase_keyfile:
              type: service_account
              project_id: your-project-id
              # ... other Firebase credentials
        ERROR
      end

      Google::Cloud::Firestore.new(credentials: credentials.to_h)
    end
  end
end

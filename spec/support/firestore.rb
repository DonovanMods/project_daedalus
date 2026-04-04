# frozen_string_literal: true

# Stub Firebase credentials globally so tests don't fail when
# credentials are not configured (e.g., in CI environments).
#
# Individual specs should still mock Google::Cloud::Firestore.new
# to return a test double, but this prevents the Firestorable concern
# from raising before the mock can intercept.
RSpec.configure do |config|
  config.before do
    credentials = Rails.application.credentials
    unless credentials.respond_to?(:firebase_keyfile) && credentials.firebase_keyfile.present?
      allow(Rails.application.credentials).to receive(:firebase_keyfile).and_return(
        { type: "service_account", project_id: "test-project" }
      )
    end

    # Stub SiteContent.find globally so info page specs don't hit Firestore
    if defined?(SiteContent)
      allow(SiteContent).to receive(:find).and_return(nil)
    end
  end
end

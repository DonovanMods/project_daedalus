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

    # Stub Vote model methods globally so specs that render mod pages
    # don't hit Firestore for vote counts
    if defined?(Vote)
      allow(Vote).to receive_messages(count_for: 0, counts_for: {}, exists?: false, rate_limited?: false)
    end
  end

  # Reset memoized Firestore clients after each test to prevent
  # RSpec test doubles from leaking across examples via the
  # class-level @firestore ||= memoization in Firestorable.
  config.after do
    [Mod, Tool].each do |klass|
      klass.instance_variable_set(:@firestore, nil) if klass.instance_variable_defined?(:@firestore)
    end
    if defined?(SiteContent) && SiteContent.respond_to?(:instance_variable_set) &&
       SiteContent.instance_variable_defined?(:@firestore)
      SiteContent.instance_variable_set(:@firestore, nil)
    end
  end
end

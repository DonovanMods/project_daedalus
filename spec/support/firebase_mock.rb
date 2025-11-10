# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:each, type: :request) do
    # Mock the Mod and Tool firestore methods to prevent auth errors in request tests
    allow(Mod).to receive(:firestore).and_return(nil)
    allow(Tool).to receive(:firestore).and_return(nil)

    # Mock the Mod.all and Tool.all methods to return empty arrays
    allow(Mod).to receive(:all).and_return([])
    allow(Tool).to receive(:all).and_return([])
  end
end

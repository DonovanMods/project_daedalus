# frozen_string_literal: true

require "rails_helper"

RSpec.describe SiteContent do
  let(:firestore_client) { instance_double(Google::Cloud::Firestore::Client) }
  let(:doc_ref) { instance_double(Google::Cloud::Firestore::DocumentReference) }

  before do
    allow(Google::Cloud::Firestore).to receive(:new).and_return(firestore_client)
    allow(firestore_client).to receive(:doc).and_return(doc_ref)
    # Override global SiteContent.find stub so we test real implementation
    allow(described_class).to receive(:find).and_call_original
    Rails.cache.clear
  end

  describe ".find" do
    context "when Firestore document exists" do
      let(:doc_snapshot) do
        instance_double(Google::Cloud::Firestore::DocumentSnapshot,
                        exists?: true,
                        :[] => nil)
      end

      before do
        allow(doc_ref).to receive(:get).and_return(doc_snapshot)
        allow(doc_snapshot).to receive(:[]).with(:sections).and_return(
          [{ title: "Test Section", description: "A description", link_text: "Click", link_url: "https://example.com" }]
        )
        allow(doc_snapshot).to receive(:[]).with(:updated_at).and_return(Time.utc(2026, 1, 1))
      end

      it "returns a SiteContent instance with sections" do
        content = described_class.find("info_page")
        expect(content).to be_a(described_class)
        expect(content.sections.size).to eq(1)
        expect(content.sections.first.title).to eq("Test Section")
      end
    end

    context "when Firestore document does not exist" do
      let(:doc_snapshot) { instance_double(Google::Cloud::Firestore::DocumentSnapshot, exists?: false) }

      before do
        allow(doc_ref).to receive(:get).and_return(doc_snapshot)
      end

      it "returns nil" do
        content = described_class.find("info_page")
        expect(content).to be_nil
      end
    end
  end

  describe ".save!" do
    let(:sections) do
      [SiteContent::Section.new(title: "New", description: "Desc", link_text: "Go", link_url: "https://example.com")]
    end

    before do
      allow(doc_ref).to receive(:set)
    end

    it "writes to Firestore and returns a SiteContent instance" do
      result = described_class.save!("info_page", sections)
      expect(result).to be_a(described_class)
      expect(result.sections.size).to eq(1)
      expect(doc_ref).to have_received(:set).once
    end
  end

  describe ".default_info_sections" do
    it "returns default sections with Discord and Upvote entries" do
      defaults = described_class.default_info_sections
      expect(defaults.size).to eq(2)
      expect(defaults.first.title).to include("Discord")
      expect(defaults.last.title).to include("Upvote")
    end
  end
end

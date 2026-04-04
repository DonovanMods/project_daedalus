# frozen_string_literal: true

require "rails_helper"

RSpec.describe PaginationHelper do
  include described_class

  let(:items) { (1..50).to_a }

  describe "#paginate_array" do
    it "returns the first page by default" do
      result = paginate_array(items, page: 1)
      expect(result.items).to eq((1..20).to_a)
      expect(result.current_page).to eq(1)
      expect(result.total_pages).to eq(3)
      expect(result.total_count).to eq(50)
    end

    it "returns the correct page slice" do
      result = paginate_array(items, page: 2)
      expect(result.items).to eq((21..40).to_a)
      expect(result.current_page).to eq(2)
    end

    it "returns the last page with remaining items" do
      result = paginate_array(items, page: 3)
      expect(result.items).to eq((41..50).to_a)
    end

    it "clamps page to 1 when given 0 or negative" do
      result = paginate_array(items, page: 0)
      expect(result.current_page).to eq(1)

      result = paginate_array(items, page: -5)
      expect(result.current_page).to eq(1)
    end

    it "clamps page to last page when exceeding total" do
      result = paginate_array(items, page: 999)
      expect(result.current_page).to eq(3)
      expect(result.items).to eq((41..50).to_a)
    end

    it "respects custom per_page" do
      result = paginate_array(items, page: 1, per_page: 10)
      expect(result.items).to eq((1..10).to_a)
      expect(result.total_pages).to eq(5)
    end

    it "handles empty collection" do
      result = paginate_array([], page: 1)
      expect(result.items).to eq([])
      expect(result.total_pages).to eq(0)
      expect(result.total_count).to eq(0)
    end
  end

  describe described_class::PaginationResult do
    subject(:result) do
      described_class.new(
        items: [], current_page: current_page, total_pages: 5, total_count: 100, per_page: 20
      )
    end

    context "when on the first page" do
      let(:current_page) { 1 }

      it { is_expected.to be_first_page }
      it { is_expected.not_to be_last_page }
      it { is_expected.to be_paginated }
      it { expect(result.previous_page).to be_nil }
      it { expect(result.next_page).to eq(2) }
    end

    context "when on a middle page" do
      let(:current_page) { 3 }

      it { is_expected.not_to be_first_page }
      it { is_expected.not_to be_last_page }
      it { expect(result.previous_page).to eq(2) }
      it { expect(result.next_page).to eq(4) }
    end

    context "when on the last page" do
      let(:current_page) { 5 }

      it { is_expected.not_to be_first_page }
      it { is_expected.to be_last_page }
      it { expect(result.previous_page).to eq(4) }
      it { expect(result.next_page).to be_nil }
    end

    context "with a single page" do
      subject(:result) do
        described_class.new(
          items: [], current_page: 1, total_pages: 1, total_count: 5, per_page: 20
        )
      end

      it { is_expected.not_to be_paginated }
    end

    describe "#page_range" do
      it "returns all pages when total is small" do
        result = described_class.new(
          items: [], current_page: 1, total_pages: 5, total_count: 100, per_page: 20
        )
        expect(result.page_range).to eq([1, 2, 3, 4, 5])
      end

      it "includes ellipsis for large page counts" do
        result = described_class.new(
          items: [], current_page: 10, total_pages: 20, total_count: 400, per_page: 20
        )
        range = result.page_range
        expect(range.first).to eq(1)
        expect(range.last).to eq(20)
        expect(range).to include(nil) # ellipsis markers
        expect(range).to include(10)  # current page
      end
    end
  end
end

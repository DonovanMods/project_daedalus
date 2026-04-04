# frozen_string_literal: true

module PaginationHelper
  DEFAULT_PER_PAGE = 20

  # Paginates an array and returns the current page slice
  def paginate_array(collection, page:, per_page: DEFAULT_PER_PAGE)
    page = [page.to_i, 1].max
    total = collection.size
    total_pages = (total / per_page.to_f).ceil
    page = [page, total_pages].min if total_pages > 0

    offset = (page - 1) * per_page
    items = collection[offset, per_page] || []

    PaginationResult.new(items: items, current_page: page, total_pages: total_pages, total_count: total, per_page: per_page)
  end

  class PaginationResult
    attr_reader :items, :current_page, :total_pages, :total_count, :per_page

    def initialize(items:, current_page:, total_pages:, total_count:, per_page:)
      @items = items
      @current_page = current_page
      @total_pages = total_pages
      @total_count = total_count
      @per_page = per_page
    end

    def first_page?
      current_page <= 1
    end

    def last_page?
      current_page >= total_pages
    end

    def paginated?
      total_pages > 1
    end

    def previous_page
      current_page - 1 unless first_page?
    end

    def next_page
      current_page + 1 unless last_page?
    end

    # Returns an array of page numbers with ellipsis markers (nil) for gaps
    def page_range(window: 2)
      return (1..total_pages).to_a if total_pages <= (window * 2) + 5

      pages = []
      pages << 1

      left = [current_page - window, 2].max
      right = [current_page + window, total_pages - 1].min

      pages << nil if left > 2
      (left..right).each { |p| pages << p }
      pages << nil if right < total_pages - 1

      pages << total_pages
      pages
    end
  end
end

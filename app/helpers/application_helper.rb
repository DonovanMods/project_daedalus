# frozen_string_literal: true

module ApplicationHelper
  def current_path
    request.env["PATH_INFO"]
  end

  class CodeRayify < Redcarpet::Render::HTML
    TABLE_ALIGNMENT = { left: "text-left", center: "text-center", right: "text-right" }.freeze

    def block_code(code, language)
      CodeRay.scan(code, language || :text).div
    end

    # A table wider than the text column scrolls sideways inside this wrapper instead of widening the page.
    def table(header, body)
      %(<div class="table-scroll"><table><thead>\n#{header}</thead><tbody>\n#{body}</tbody></table></div>\n)
    end

    # Redcarpet puts column alignment in a style attribute, which the sanitizer removes. A class survives.
    def table_cell(content, alignment, header)
      tag = header ? "th" : "td"
      css = TABLE_ALIGNMENT[alignment]
      css ? %(<#{tag} class="#{css}">#{content}</#{tag}>\n) : "<#{tag}>#{content}</#{tag}>\n"
    end
  end

  # Rails' default safe list has no table tags, so the sanitizer would strip what the tables extension renders.
  MARKDOWN_TABLE_TAGS = %w[table thead tbody tr th td].freeze

  MARKDOWN_OPTIONS = {
    fenced_code_blocks: true,
    no_intra_emphasis: true,
    autolink: true,
    lax_html_blocks: true
  }.freeze

  # Redcarpet pads every table row to the header's width, so a few kilobytes of pipes can come out as millions
  # of cells. Past this bound the text is rendered without tables. The largest README listed today needs ~600.
  MAX_TABLE_CELLS = 20_000

  def markdown(text)
    return if text.blank?

    renderer = table_cell_bound(text) > MAX_TABLE_CELLS ? plain_markdown_renderer : markdown_renderer
    sanitize(renderer.render(text), tags: markdown_tags)
  end

  private

  def markdown_tags
    @markdown_tags ||= ActionView::Base.sanitized_allowed_tags.to_a + MARKDOWN_TABLE_TAGS
  end

  # The most cells Redcarpet could emit: every line that holds a pipe, as wide as the widest of them.
  # Redcarpet ends a line at a lone carriage return as well as at a line feed, so this splits on both.
  def table_cell_bound(text)
    pipes = text.split(/[\r\n]+/).map { |line| line.count("|") }.reject(&:zero?)
    pipes.size * (pipes.max.to_i + 1)
  end

  def markdown_renderer
    @markdown_renderer ||= build_markdown_renderer(tables: true)
  end

  def plain_markdown_renderer
    @plain_markdown_renderer ||= build_markdown_renderer(tables: false)
  end

  def build_markdown_renderer(tables:)
    coderayified = CodeRayify.new(filter_html: true, hard_wrap: true)
    Redcarpet::Markdown.new(coderayified, MARKDOWN_OPTIONS.merge(tables: tables))
  end
end

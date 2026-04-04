# frozen_string_literal: true

module ApplicationHelper
  def current_path
    request.env["PATH_INFO"]
  end

  class CodeRayify < Redcarpet::Render::HTML
    def block_code(code, language)
      CodeRay.scan(code, language || :text).div
    end
  end

  def markdown(text)
    return if text.blank?

    sanitize(markdown_renderer.render(text))
  end

  private

  def markdown_renderer
    @markdown_renderer ||= begin
      coderayified = CodeRayify.new(filter_html: true, hard_wrap: true)

      options = {
        fenced_code_blocks: true,
        no_intra_emphasis: true,
        autolink: true,
        lax_html_blocks: true
      }

      Redcarpet::Markdown.new(coderayified, options)
    end
  end
end

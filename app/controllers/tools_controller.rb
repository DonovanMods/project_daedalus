# frozen_string_literal: true

class ToolsController < ApplicationController
  before_action :tools, only: %i[index]

  def index
    @tools = find_by_author(sanitize(params[:author])) if params[:author].present?
  end

  private

  def tools
    @tools ||= Tool.all
  end

  def find_by_author(author)
    @tools.find_all { |tool| tool.author_slug.casecmp(author.parameterize).zero? }
  end
end

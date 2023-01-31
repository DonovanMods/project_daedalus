# frozen_string_literal: true

class ToolsController < ApplicationController
  before_action :fetch_tools, only: %i[index]

  def index
    @tools = find_by_author(sanitize(params[:author])) if params[:author].present?
  end

  private

  def fetch_tools
    @tools ||= Tool.all
    @authors = @tools.map(&:author).uniq.sort
  end

  def find_by_author(author)
    @tools.find_all { |tool| tool.author.casecmp(author).zero? }
  end
end

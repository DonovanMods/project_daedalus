# frozen_string_literal: true

class ToolsController < ApplicationController
  before_action :fetch_tools, only: %i[index show]

  def index; end

  def show; end

  private

  def fetch_tools
    @tools = Tool.all
    @authors = @tools.map(&:author).uniq.sort
  end
end

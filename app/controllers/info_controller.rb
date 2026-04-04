# frozen_string_literal: true

# InfoController
class InfoController < ApplicationController
  def index
    content = SiteContent.find("info_page")
    @sections = content&.sections || SiteContent.default_info_sections
    @last_updated = content&.updated_at
  end
end

# frozen_string_literal: true

module Admin
  # Allows admins to edit the info page content stored in Firestore.
  class InfoController < Admin::BaseController
    def edit
      content = SiteContent.find("info_page")
      @sections = content&.sections || SiteContent.default_info_sections
    end

    def update
      sections = build_sections_from_params
      SiteContent.save!("info_page", sections)
      redirect_to admin_info_edit_path, notice: "Info page updated successfully."
    end

    # Add a blank section to the form
    def add_section
      content = SiteContent.find("info_page")
      sections = content&.sections || SiteContent.default_info_sections
      sections << SiteContent::Section.new(title: "", description: "", link_text: "", link_url: "")
      SiteContent.save!("info_page", sections)
      redirect_to admin_info_edit_path, notice: "New section added."
    end

    # Remove a section by index
    def remove_section
      content = SiteContent.find("info_page")
      sections = content&.sections || SiteContent.default_info_sections
      index = params[:index].to_i
      sections.delete_at(index) if index >= 0 && index < sections.size
      SiteContent.save!("info_page", sections)
      redirect_to admin_info_edit_path, notice: "Section removed."
    end

    private

    def build_sections_from_params
      return [] unless params[:sections].is_a?(ActionController::Parameters)

      params[:sections].values.map do |section_params|
        SiteContent::Section.new(
          title: section_params[:title].to_s.strip,
          description: section_params[:description].to_s.strip,
          link_text: section_params[:link_text].to_s.strip,
          link_url: section_params[:link_url].to_s.strip
        )
      end.reject { |s| s.title.blank? && s.description.blank? }
    end
  end
end

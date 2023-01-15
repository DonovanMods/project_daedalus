# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include ActionView::Helpers::SanitizeHelper
end

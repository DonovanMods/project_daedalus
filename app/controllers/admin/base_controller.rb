# frozen_string_literal: true

module Admin
  # Base controller for admin routes.
  # Uses HTTP Basic Auth with a password set via ADMIN_PASSWORD env var.
  class BaseController < ApplicationController
    before_action :authenticate_admin!

    private

    def authenticate_admin!
      admin_password = ENV.fetch("ADMIN_PASSWORD", nil)

      if admin_password.blank?
        render plain: "Admin access is not configured. Set the ADMIN_PASSWORD environment variable.", status: :service_unavailable
        return
      end

      authenticate_or_request_with_http_basic("Project Daedalus Admin") do |_username, password|
        ActiveSupport::SecurityUtils.secure_compare(password, admin_password)
      end
    end
  end
end

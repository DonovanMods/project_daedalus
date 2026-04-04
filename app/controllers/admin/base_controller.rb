# frozen_string_literal: true

module Admin
  # Base controller for admin routes.
  # Uses session-based authentication with ADMIN_PASSWORD env var.
  # Sessions expire after 30 minutes of inactivity.
  class BaseController < ApplicationController
    SESSION_TIMEOUT = 30.minutes

    before_action :authenticate_admin!

    private

    def authenticate_admin!
      admin_password = ENV.fetch("ADMIN_PASSWORD", nil)

      if admin_password.blank?
        render plain: "Admin access is not configured. Set the ADMIN_PASSWORD environment variable.",
               status: :service_unavailable
        return
      end

      if session[:admin_authenticated]
        if session[:admin_last_active].present? &&
           Time.current - Time.zone.parse(session[:admin_last_active].to_s) < SESSION_TIMEOUT
          session[:admin_last_active] = Time.current.iso8601
          return
        end

        reset_admin_session
        redirect_to admin_login_path, alert: "Session expired. Please log in again."
        return
      end

      redirect_to admin_login_path
    end

    def reset_admin_session
      session.delete(:admin_authenticated)
      session.delete(:admin_last_active)
    end
  end
end

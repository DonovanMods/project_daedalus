# frozen_string_literal: true

module Admin
  class SessionsController < ApplicationController
    def new
      # Login form
      redirect_to admin_info_edit_path if session[:admin_authenticated]
    end

    def create
      admin_password = ENV.fetch("ADMIN_PASSWORD", nil)

      if admin_password.blank?
        render plain: "Admin access is not configured.", status: :service_unavailable
        return
      end

      if ActiveSupport::SecurityUtils.secure_compare(params[:password].to_s, admin_password)
        session[:admin_authenticated] = true
        session[:admin_last_active] = Time.current.iso8601
        Rails.logger.info("[Admin] Successful login from #{request.remote_ip}")
        redirect_to admin_info_edit_path, notice: "Logged in successfully."
      else
        Rails.logger.warn("[Admin] Failed login attempt from #{request.remote_ip}")
        flash.now[:alert] = "Invalid password."
        render :new, status: :unauthorized
      end
    end

    def destroy
      Rails.logger.info("[Admin] Logout from #{request.remote_ip}")
      session.delete(:admin_authenticated)
      session.delete(:admin_last_active)
      redirect_to root_path, notice: "Logged out."
    end
  end
end

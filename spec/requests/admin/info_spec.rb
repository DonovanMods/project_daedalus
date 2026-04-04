# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Info", type: :request do
  let(:firestore_client) { instance_double(Google::Cloud::Firestore::Client) }
  let(:doc_ref) { instance_double(Google::Cloud::Firestore::DocumentReference) }
  let(:admin_password) { "test-admin-password" }

  before do
    allow(Google::Cloud::Firestore).to receive(:new).and_return(firestore_client)
    allow(firestore_client).to receive(:doc).and_return(doc_ref)
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("ADMIN_PASSWORD", nil).and_return(admin_password)
    Rails.cache.clear
  end

  # Helper to log in via the session-based admin auth
  def admin_login
    post admin_login_path, params: { password: admin_password }
  end

  describe "GET /admin/info" do
    context "without authentication" do
      it "redirects to login" do
        get admin_info_edit_path
        expect(response).to redirect_to(admin_login_path)
      end
    end

    context "with valid session" do
      it "returns 200 and renders edit form" do
        allow(doc_ref).to receive(:get).and_return(
          instance_double(Google::Cloud::Firestore::DocumentSnapshot, exists?: false)
        )
        admin_login
        get admin_info_edit_path
        expect(response).to have_http_status(:ok)
      end
    end

    context "when ADMIN_PASSWORD is not set" do
      before do
        allow(ENV).to receive(:fetch).with("ADMIN_PASSWORD", nil).and_return(nil)
      end

      it "returns 503" do
        get admin_info_edit_path
        expect(response).to have_http_status(:service_unavailable)
      end
    end
  end

  describe "POST /admin/login" do
    it "logs in with correct password and redirects" do
      post admin_login_path, params: { password: admin_password }
      expect(response).to redirect_to(admin_info_edit_path)
    end

    it "rejects incorrect password" do
      post admin_login_path, params: { password: "wrong" }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "DELETE /admin/logout" do
    it "clears session and redirects to root" do
      admin_login
      delete admin_logout_path
      expect(response).to redirect_to(root_path)
    end
  end
end

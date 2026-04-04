# frozen_string_literal: true

class VotesController < ApplicationController
  def create
    mod = find_mod
    return render json: { error: "Mod not found" }, status: :not_found unless mod

    fingerprint = params[:fingerprint].to_s.strip
    return render json: { error: "Invalid request" }, status: :unprocessable_content if fingerprint.blank?

    # Rate limiting
    if Vote.rate_limited?(fingerprint)
      return render json: { error: "Too many votes, please slow down" }, status: :too_many_requests
    end

    if Vote.exists?(mod.id, fingerprint)
      # Already voted — toggle it off (unvote)
      Vote.remove!(mod.id, fingerprint)
      render json: { voted: false, count: Vote.count_for(mod.id) }
    else
      # New vote
      Vote.cast!(mod.id, fingerprint)
      render json: { voted: true, count: Vote.count_for(mod.id) }
    end
  rescue StandardError => e
    Rails.logger.error("Vote error: #{e.class} - #{e.message}")
    render json: { error: "Something went wrong" }, status: :internal_server_error
  end

  private

  def find_mod
    Mod.all.find do |mod|
      mod.author_slug.casecmp(params[:author].parameterize)&.zero? &&
        mod.slug.casecmp(params[:slug])&.zero?
    end
  end
end

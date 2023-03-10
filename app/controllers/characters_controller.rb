class CharactersController < ApplicationController
  def index
    @characters = Character.all

    if turbo_frame_request?
      render partial: "characters", locals: {characters: @characters}
    else
      render :index
    end
  end
end

class CharactersController < ApplicationController
  def index
    @characters = Icarus::Character.all

    if turbo_frame_request?
      render partial: "characters", locals: {characters: @characters}
    else
      render "icarus/characters/index"
    end
  end
end

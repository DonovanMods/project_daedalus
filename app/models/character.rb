# characters.json Reference: https://pastebin.com/eZXP1Msq

# Icarus Character
class Character
  include ActiveModel::Model
  include ActionView::Helpers::NumberHelper

  @characters = []

  ##
  ## Class methods
  ##
  class << self
    def all
      parse File.read(Rails.root.join("spec/fixtures/characters.json"))
      @characters
    end

    def parse(raw_json)
      @characters = JSON.parse(raw_json)["Characters.json"].map { |c| new(c) }
    end

    def to_json
      JSON.generate({"Characters.json": all.map(&:to_json)}, {
        array_nl: "\r\n",
        object_nl: "\r\n",
        indent: "\t",
        space_before: "",
        space: " "
      })
    end
  end

  ##
  ## Instance methods
  ##
  attr_reader :data

  def initialize(data)
    @data = JSON.parse(data)
  end

  def abandoned?
    @data["IsAbandoned"]
  end

  def abandoned=(value)
    @data["IsAbandoned"] = !!value
  end

  def credits
    @credits ||= @data["MetaResources"].find { |r| r["MetaRow"] == "Credits" }&.dig("Count").to_i
  end

  def dead?
    @data["IsDead"]
  end

  def dead=(value)
    @data["IsDead"] = !!value
  end

  def exotics
    @credits ||= @data["MetaResources"].find { |r| r["MetaRow"] == "Exotic1" }&.dig("Count").to_i
  end

  def location
    @data["Location"]
  end

  def name
    @data["CharacterName"]
  end

  def refund
    @refund ||= @data["MetaResources"].find { |r| r["MetaRow"] == "Refund" }&.dig("Count")&.to_i
  end

  def talents
    @talents ||= {}

    return @talents unless @talents.empty?

    @data["Talents"].each { |t| @talents[t["RowName"]] = t["Rank"] }

    @talents
  end

  def to_json
    JSON.generate(@data, {
      array_nl: "",
      object_nl: "\r\n\t",
      indent: "",
      space_before: "",
      space: " "
    })
  end

  def xp
    @data["XP"].to_i
  end

  def xp=(value)
    @data["XP"] = value.to_i
  end

  def xp_debt
    @data["XP_Debt"].to_i
  end

  def xp_debt=(value)
    @data["XP_Debt"] = value.to_i
  end

  def xp_string
    [number_with_delimiter(xp), xp_debt.positive? ? "(#{number_with_delimiter(xp_debt)} debt)" : nil].compact.join(" ")
  end
end

# characters.json Reference: https://pastebin.com/eZXP1Msq

# Icarus Character
class Character
  @characters = []

  ##
  ## Class methods
  ##
  class << self
    def all
      @characters
    end

    def parse(raw_json)
      @characters = JSON.parse(raw_json)["Characters.json"].map { |c| new(c) }
    end

    def to_json
      JSON.generate({"Characters.json": all.map(&:to_json)}, {
        array_nl: "\r\n",
        object_nl: "\r\n",
        indent: "  ",
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

  def name
    @data["CharacterName"]
  end

  def xp
    @data["XP"].to_i
  end

  def xp_debt
    @data["XP_Debt"].to_i
  end

  def xp_string
    "#{xp} #{xp_debt.positive? ? "(#{xp_debt} debt)" : ""}"
  end

  def dead?
    @data["IsDead"]
  end

  def abandoned?
    @data["IsAbandoned"]
  end

  def location
    @data["Location"]
  end

  def credits
    @credits ||= @data["MetaResources"].find { |r| r["MetaRow"] == "Credits" }&.dig("Count")&.to_i
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
end


# characters = JSON.parse(ARGF.read)["Characters.json"].map { |c| IcarusCharacter.new(c) }

# puts characters[0].data.keys

# characters.each do |character|
#   puts character.print + "\n\n"
# end

# File.write(
#   "characters.test.json",
#   JSON.generate({"Characters.json": characters.map(&:to_json)}, {
#     array_nl: "\r\n",
#     object_nl: "\r\n",
#     indent: "  ",
#     space_before: "",
#     space: " "
#   })
# )

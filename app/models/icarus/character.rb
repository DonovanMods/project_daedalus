# characters.json Reference: https://pastebin.com/eZXP1Msq

# Icarus Character
module Icarus
  class Character < IcarusRecord
    STANDARD_LEVEL_MATRIX = {
      0 => 0, 2400 => 1, 8610 => 2, 18_730 => 3, 32_530 => 4, 48_630 => 5, 67_830 => 6, 89_430 => 7, 111_030 => 8, 135_030 => 9, 161_500 => 10,
      194_400 => 11, 227_300 => 12, 260_200 => 13, 293_100 => 14, 326_000 => 15, 380_800 => 16, 435_600 => 17, 490_400 => 18, 545_200 => 19, 600_000 => 20,
      975_000 => 25, 1_400_000 => 30, 1_942_000 => 35, 2_550_000 => 40, 3_200_000 => 45, 3_890_000 => 50, 4_625_000 => 55, 5_400_000 => 60
    }.freeze
    @@characters = []

    ##
    ## Class methods
    ##
    class << self
      def all
        @@characters
      end

      def loaded?
        @@characters.any?
      end

      def parse(raw_json)
        @@characters = JSON.parse(raw_json)["Characters.json"].map { |c| new(c) }
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
    def abandoned?
      @data["IsAbandoned"]
    end

    def abandoned=(value)
      @data["IsAbandoned"] = !!value
    end

    def dead?
      @data["IsDead"]
    end

    def dead=(value)
      @data["IsDead"] = !!value
    end

    def level
      STANDARD_LEVEL_MATRIX.filter { |xp, level| self.xp >= xp }.values.max
    end

    def level=(value)
      return unless value.positive? && value <= 60

      xp = STANDARD_LEVEL_MATRIX.select { |xp, level| level == value }.keys.first + 1
      self.xp = xp
    end

    def location
      @data["Location"]
    end

    def name
      @data["CharacterName"]
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
end

# Icarus Character
module Icarus
  class Profile < IcarusRecord
    @@profile = nil

    ##
    ## Class methods
    ##
    class << self
      def loaded?
        !!@@profile&.data&.any?
      end

      def parse(raw_json)
        @@profile = new raw_json
      end

      def to_json
        JSON.generate(@@profile.data, {
          array_nl: "\r\n",
          object_nl: "\r\n",
          indent: "\t",
          space_before: "",
          space: " "
        })
      end
    end
  end
end

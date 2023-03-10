# Icarus Character
module Icarus
  class Profile < IcarusRecord
    ##
    ## Class methods
    ##
    class << self
      def parse(raw_json)
        @profile = new raw_json
      end

      def to_json
        JSON.generate(@profile.data, {
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

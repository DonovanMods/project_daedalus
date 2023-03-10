# frozen_string_literal: true

module Icarus
  class IcarusRecord
    include ActiveModel::Model
    include ActionView::Helpers::NumberHelper

    ##
    ## Instance methods
    ##
    attr_reader :data

    def initialize(data)
      @data = JSON.parse(data)
    end

    def credits
      meta_resource("Credits")&.dig("Count").to_i
    end

    def credits=(value)
      update_meta_resources("Credits", value)
    end

    def exotics
      meta_resource("Exotic1")&.dig("Count").to_i
    end

    def exotics=(value)
      update_meta_resources("Exotic1", value)
    end

    def refund
      meta_resource("Refund")&.dig("Count").to_i
    end

    def refund=(value)
      update_meta_resources("Refund", value)
    end

    def talents
      @data["Talents"].to_h { |t| [t["RowName"], t["Rank"]] }
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

    private

    def meta_resource(resource)
      @data["MetaResources"].find { |r| r["MetaRow"] == resource }
    end

    def update_meta_resources(resource, amount)
      resource_data = meta_resource(resource)

      if resource_data
        resource_data["Count"] = amount
      else
        @data["MetaResources"] << {"MetaRow" => resource, "Count" => amount}
      end

      meta_resource(resource)["Count"].to_i
    end
  end
end

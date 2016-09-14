require_relative '../models/plant'

module FBPi
  # Download all Plant objects (JSON) off of Farmbot Web API, convert them to
  # Ruby objects, save them in SQLite.
  class CreatePlant < Mutations::Command
    required do
      string  :id
      integer :x
      integer :y
    end

    def validate
      inputs[:id_on_web_app] = inputs.delete(:id)
    end

    def execute
      Plant.create!(inputs)
    end
  end
end

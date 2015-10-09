require_relative '../models/plant'
binding.pry
module FBPi
  # Download all Plant objects (JSON) off of Farmbot Web API, convert them to
  # Ruby objects, save them in SQLite.
  class CreatePlant < Mutations::Command
    required do
      string  :_id
      integer :x
      integer :y
    end

    def validate
      inputs[:id_on_web_app] = inputs.delete(:_id)
    end

    def execute
      Plant.create!(inputs)
    end
  end
end

# data classes for the command queue

class Command
  include Mongoid::Document

  embeds_many :commandlines

  field :plant_id
  field :scheduled_time
  field :executed_time
  field :status

end

class Commandline
  include Mongoid::Document

  embedded_in :command
  #belongs_to :command

  field :action
  field :coord_x
  field :coord_y
  field :coord_z
  field :speed
  field :amount
end

class Refresh
  include Mongoid::Document

  field :name
  field :value
end


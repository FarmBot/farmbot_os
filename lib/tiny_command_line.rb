# This is a temporary class that I am using to bypass the database (for now).
# Delete after debugging.
# class TinyCommandLine
#   ATTRS = [:command_id, :action, :coord_x, :coord_y, :coord_z, :speed,
#     :amount, :created_at, :updated_at, :pin_nr, :pin_mode, :pin_value_1,
#     :pin_value_2, :pin_time, :external_info]

#   attr_accessor *ATTRS

#   def initialize(input = {})
#     # Disallow unsafe access
#     raise 'Bad key in input' if (ATTRS & input.keys).length != input.keys.length
#     input.each { |key, value| self.send("#{key}=", value) }
#   end
# end

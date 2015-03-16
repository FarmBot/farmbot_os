class Status
  attr_accessor :command_refresh, :device_version, :emergency_stop,
    :info_command_last, :info_command_next, :info_current_x,
    :info_current_x_steps, :info_current_y, :info_current_y_steps,
    :info_current_z, :info_current_z_steps, :info_end_stop_x_a,
    :info_end_stop_x_b, :info_end_stop_y_a, :info_end_stop_y_b,
    :info_end_stop_z_a, :info_end_stop_z_b, :info_movement,
    :info_nr_of_commands, :info_status, :info_target_x, :info_target_y,
    :info_target_z

    class << self
      attr_accessor :current

      def current
        @current ||= self.new
      end
    end

  def initialize

    @emergency_stop       = false;

    @info_command_next    = nil
    @info_command_last    = nil
    @info_nr_of_commands  = 0
    @info_status          = 'initializing'
    @info_movement        = 'idle'

    @info_current_x_steps = 0
    @info_current_y_steps = 0
    @info_current_z_steps = 0

    @info_current_x       = 0
    @info_current_y       = 0
    @info_current_z       = 0

    @info_target_x        = 0
    @info_target_y        = 0
    @info_target_z        = 0

    @info_end_stop_x_a    = 0
    @info_end_stop_x_b    = 0
    @info_end_stop_y_a    = 0
    @info_end_stop_y_b    = 0
    @info_end_stop_z_a    = 0
    @info_end_stop_z_b    = 0

    @command_refresh      = 0
    @device_version       = 'UNKNOWN'

  end

end

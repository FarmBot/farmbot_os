Dir['lib/controllers/**/*.rb'].each { |file| load(file) }

module FBPi
  # Uses a string such as 'single_command.MOVE RELATIVE' and resolves it to a
  # particular controller, or returns UnknownController. Be sure to add new
  # controllers and RPC commands to the ROUTES constant.
  class ResolveController < Mutations::Command

    ROUTES = {
      'single_command'     => SingleCommandController,
      'read_status'        => ReadStatusController,
      'exec_sequence'      => ExecSequenceController,
      'sync_sequence'      => SyncSequenceController,
      'update_calibration' => UpdateCalibrationController,
      'unknown'            => UnknownController,
    }

    optional do
      string :method, default: ''
    end

    def execute
      ROUTES[method.to_s.split('.').first] || UnknownController
    end
  end
end

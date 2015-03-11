require_relative 'dbaccess'

# read the test file and convert it into one command
class TestFileHandler

  def self.readCommandFile

    DbAccess.current.clear_schedule()

    if File.file?('testcommands.csv')
      DbAccess.current.create_new_command(Time.now,'file')
      f = File.open('testcommands.csv','r')
      f.each_line do |line|
        if line.length > 5
          #cmd_line = ControlCommandLine.new
          #cmd_line.parseText( line )
          #cmd.lines << cmd_line
          params = line.split(',')
          action = params[0].to_s
          xCoord = params[1].to_i
          yCoord = params[2].to_i
          zCoord = params[3].to_i
          amount = params[4].to_i
          DbAccess.current.add_command_line(action, xCoord, yCoord, zCoord, 0, amount)
        end
      end
      DbAccess.current.save_new_command
    end
  end
end

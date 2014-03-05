require_relative 'dbaccess'

# read the test file and convert it into one command
class TestFileHandler

  def self.readCommandFile
    if File.file?('testcommands.csv')
      $bot_dbaccess.create_new_command(Time.now)
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
          $bot_dbaccess.add_command_line(action, xCoord, yCoord, zCoord, 0, 0)
        end
      end
      $bot_dbaccess.save_new_command
    end
  end
end

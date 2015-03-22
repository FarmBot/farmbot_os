puts '[FarmBot Controller Menu]'
puts 'starting up'

require './lib/database/dbaccess.rb'
require './lib/database/filehandler.rb'

$db_write_sync = Mutex.new

#require './lib/controller.rb'
#require "./lib/hardware/ramps.rb"

db = DbAccess.current
$shutdown    = 0

# just a little menu for testing


$move_size      = 10
$command_delay  = 0
$pin_nr         = 13
$servo_angle    = 0

while $shutdown == 0 do

  #system('cls')
  system('clear')

  puts '[FarmBot Controller Menu]'
  puts ''
  puts 't - execute test'
  puts ''
  puts "move size = #{$move_size}"
  puts "command delay = #{$command_delay}"
  puts "pin nr = #{$pin_nr}"
  puts "servo angle = #{$servo_angle}"
  puts ''
  puts 'w - forward'
  puts 's - back'
  puts 'a - left'
  puts 'd - right'
  puts 'r - up'
  puts 'f - down'
  puts ''
  puts 'z - home z axis'
  puts 'x - home x axis'
  puts 'c - home y axis'
  puts ''
  puts 'y - dose water'
  puts 'u - set pin on'
  puts 'i - set pin off'
  puts 'k - move servo (pin 4,5)'
  puts ''
  puts 'q - step size'
  puts 'g - delay seconds'
  puts 'p - pin nr'
  puts 'j - servo angle (0-180)'
  puts ''
  print 'command > '
  input = gets
  puts ''

  case input.upcase[0]
#    when "P" # Quit
#      $shutdown = 1
#      puts 'Shutting down...'
    when "O" # Get status
      puts 'Not implemented yet. Press \'Enter\' key to continue.'
      gets
    when "J" # Set servo angle
      print 'Enter new servo angle > '
      servo_angle_temp = gets
      $servo_angle = servo_angle_temp.to_i if servo_angle_temp.to_i >= 0
    when "Q" # Set step size
      print 'Enter new step size > '
      move_size_temp = gets
      $move_size = move_size_temp.to_i if move_size_temp.to_i > 0
    when "G" # Set step delay (seconds)
      print 'Enter new delay in seconds > '
      command_delay_temp = gets
      $command_delay = command_delay_temp.to_i if command_delay_temp.to_i > 0
    when "P" # Set pin number
      print 'Enter new pin nr > '
      pin_nr_temp = gets
      $pin_nr = pin_nr_temp.to_i if pin_nr_temp.to_i > 0
    when "T" # Execute test file
      # read the file
      #TestFileHandler.readCommandFile

      db.create_new_command(Time.now + $command_delay,'menu')
      db.add_command_line('CALIBRATE X', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
      db.save_new_command
      db.increment_refresh
    when "K" # Move Servo
      db.create_new_command(Time.now + $command_delay,'menu')
      db.add_command_line('SERVO MOVE', 0, 0, 0, 0, 0, $pin_nr, $servo_angle, 0, 0, 0)
      db.save_new_command
      db.increment_refresh
    when "I" # Set Pin Off
      db.create_new_command(Time.now + $command_delay,'menu')
      db.add_command_line('PIN WRITE', 0, 0, 0, 0, 0, $pin_nr, 0, 0, 0, 0)
      db.save_new_command
      db.increment_refresh
    when "U" # Set Pin On
      db.create_new_command(Time.now + $command_delay,'menu')
      db.add_command_line('PIN WRITE', 0, 0, 0, 0, 0, $pin_nr, 1, 0, 0, 0)
      db.save_new_command
      db.increment_refresh
    when "Y" # Dose water
      db.create_new_command(Time.now + $command_delay,'menu')
      db.add_command_line('DOSE WATER', 0, 0, 0, 0, 15, 0,0,0,0,0)
      db.save_new_command
      db.increment_refresh
    when "Z" # Move to home
      db.create_new_command(Time.now + $command_delay,'menu')
      db.add_command_line('HOME Z', 0, 0, 0, 0, 0, 0,0,0,0,0)
      db.save_new_command
      db.increment_refresh
    when "X" # Move to home
      db.create_new_command(Time.now + $command_delay,'menu')
      db.add_command_line('HOME X', 0, 0, 0, 0, 0, 0,0,0,0,0)
      db.save_new_command
      db.increment_refresh
    when "C" # Move to home
      db.create_new_command(Time.now + $command_delay,'menu')
      db.add_command_line('HOME Y',0 ,0 ,-$move_size, 0, 0, 0,0,0,0,0)
      db.save_new_command
      db.increment_refresh
    when "W" # Move forward
      db.create_new_command(Time.now + $command_delay,'menu')
      db.add_command_line('MOVE RELATIVE',0,$move_size, 0, 0, 0, 0,0,0,0,0)
      db.save_new_command
      db.increment_refresh
    when "S" # Move back
      db.create_new_command(Time.now + $command_delay,'menu')
      db.add_command_line('MOVE RELATIVE',0,-$move_size, 0, 0, 0, 0,0,0,0,0)
      db.save_new_command
      db.increment_refresh
    when "A" # Move left
      db.create_new_command(Time.now + $command_delay,'menu')
      db.add_command_line('MOVE RELATIVE', -$move_size, 0, 0, 0, 0, 0,0,0,0,0)
      db.save_new_command
      db.increment_refresh
    when "D" # Move right
      db.create_new_command(Time.now + $command_delay,'menu')
      db.add_command_line('MOVE RELATIVE', $move_size, 0, 0, 0, 0, 0,0,0,0,0)
      db.save_new_command
      db.increment_refresh
    when "R" # Move up
      db.create_new_command(Time.now + $command_delay,'menu')
      db.add_command_line('MOVE RELATIVE', 0, 0, $move_size, 0, 0, 0,0,0,0,0)
      db.save_new_command
      db.increment_refresh
    when "F" # Move down
      db.create_new_command(Time.now + $command_delay,'menu')
      db.add_command_line("MOVE RELATIVE", 0, 0, -$move_size, 0, 0, 0,0,0,0,0)
      db.save_new_command
      db.increment_refresh
    end

end



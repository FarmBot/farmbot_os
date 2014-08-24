system('clear')
puts 'parameter settings'

$shutdown = 0
$db_write_sync = Mutex.new

require 'active_record'
require_relative 'lib/database/dbaccess'
$bot_dbaccess = DbAccess.new
puts 'connected to database'
puts 'writing settings'

def write(name, value)

  puts "#{name} = #{value}"
  $bot_dbaccess.write_parameter(name, value)

end

write('MOVEMENT_TIMEOUT_X'           ,   15)
write('MOVEMENT_TIMEOUT_Y'           ,   15)
write('MOVEMENT_TIMEOUT_Z'           ,   15)
write('MOVEMENT_INVERT_ENDPOINTS_X'  ,    0)
write('MOVEMENT_INVERT_ENDPOINTS_Y'  ,    0)
write('MOVEMENT_INVERT_ENDPOINTS_Z'  ,    0)
write('MOVEMENT_INVERT_MOTOR_X'      ,    0)
write('MOVEMENT_INVERT_MOTOR_Y'      ,    0)
write('MOVEMENT_INVERT_MOTOR_Z'      ,    0)
write('MOVEMENT_STEPS_ACC_DEC_X'     ,  250)
write('MOVEMENT_STEPS_ACC_DEC_Y'     ,  250)
write('MOVEMENT_STEPS_ACC_DEC_Z'     ,  250)
write('MOVEMENT_HOME_UP_X'           ,    0)
write('MOVEMENT_HOME_UP_Y'           ,    0)
write('MOVEMENT_HOME_UP_Z'           ,    1)
write('MOVEMENT_MIN_SPD_X'           ,  220)
write('MOVEMENT_MIN_SPD_Y'           ,  220)
write('MOVEMENT_MIN_SPD_Z'           ,  220)
write('MOVEMENT_MAX_SPD_X'           , 2200)
write('MOVEMENT_MAX_SPD_Y'           , 2200)
write('MOVEMENT_MAX_SPD_Z'           , 2200)


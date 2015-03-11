system('clear')
puts 'parameter settings'

$shutdown = 0
$db_write_sync = Mutex.new

require 'active_record'
require_relative 'lib/database/dbaccess'
puts 'writing settings'

def write(name, value)

  puts "#{name} = #{value}"
  DbAccess.current.write_parameter(name, value)

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
write('MOVEMENT_STEPS_ACC_DEC_X'     ,  200)
write('MOVEMENT_STEPS_ACC_DEC_Y'     ,  200)
write('MOVEMENT_STEPS_ACC_DEC_Z'     ,  200)
write('MOVEMENT_HOME_UP_X'           ,    0)
write('MOVEMENT_HOME_UP_Y'           ,    0)
write('MOVEMENT_HOME_UP_Z'           ,    1)
write('MOVEMENT_MIN_SPD_X'           ,  200)
write('MOVEMENT_MIN_SPD_Y'           ,  200)
write('MOVEMENT_MIN_SPD_Z'           ,  200)
write('MOVEMENT_MAX_SPD_X'           , 4000)
write('MOVEMENT_MAX_SPD_Y'           , 4000)
write('MOVEMENT_MAX_SPD_Z'           , 4000)
write('MOVEMENT_LENGTH_X'            ,50000)
write('MOVEMENT_LENGTH_Y'            ,50000)
write('MOVEMENT_LENGTH_Z'            ,10000)
write('MOVEMENT_STEPS_PER_UNIT_X'    ,    5)
write('MOVEMENT_STEPS_PER_UNIT_Y'    ,    5)
write('MOVEMENT_STEPS_PER_UNIT_Z'    ,    5)



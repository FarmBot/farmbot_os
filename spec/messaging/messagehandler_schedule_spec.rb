require 'spec_helper'
require './lib/status.rb'
#require './lib/messaging/messaging.rb'
#require './lib/messagehandler_base'
require './lib/messaging/messagehandler.rb'
require './lib/messaging/messagehandler_schedule.rb'
require './lib/messaging/messaging_test.rb'

#require './lib/messagehandler_schedule'
#require './lib/messagehandler_schedule_cmd_line'
#require './lib/messaging/messagehandler_logs.rb'

describe MessageHandlerSchedule do

  before do
    $db_write_sync = Mutex.new
    DbAccess.current = DbAccess.new('development')
    DbAccess.current = DbAccess.current
    DbAccess.current.disable_log_to_screen()

    Status.current = Status.new

    messaging = MessengerTest.new
    messaging.reset

    @handler = MessageHandlerSchedule.new(messaging)
    @main_handler = MessageHandler.new(messaging)
  end

  ## commands / scheduling

  it "white list" do
    list = @handler.whitelist
    expect(list.count).to eq(2)
  end


  it "save command line" do

    # create new command data

    sched_time    = Time.now
    crop_id       = rand(9999999).to_i
    action        = rand(9999999).to_s
    x             = rand(9999999).to_i
    y             = rand(9999999).to_i
    z             = rand(9999999).to_i
    speed         = rand(9999999).to_s
    amount        = rand(9999999).to_i
    pin_nr        = rand(9999999).to_i
    pin_value1    = rand(9999999).to_i
    pin_value2    = rand(9999999).to_i
    pin_mode      = rand(9999999).to_i
    pin_time      = rand(9999999).to_i
    ext_info      = rand(9999999).to_s
    delay         = rand(     99).to_i

    # save the new command in the database

    command =
      {
        'action'        => action        ,
        'delay'         => delay         ,
        'x'             => x             ,
        'y'             => y             ,
        'z'             => z             ,
        'speed'         => speed         ,
        'amount'        => amount        ,
        'pin'           => pin_nr        ,
        'value1'        => pin_value1    ,
        'value2'        => pin_value2    ,
        'mode'          => pin_mode      ,
        'time'          => pin_time      ,
        'info'          => ext_info
      }

    command_obj = MessageHandlerScheduleCmdLine.new
    command_obj.split_command_line( command )

    DbAccess.current.create_new_command(sched_time,crop_id)
    @handler.save_command_line(command_obj)
    DbAccess.current.save_new_command

    # get the data back from the database

    cmd = Command.where("scheduled_time = ?",sched_time).first
    line = CommandLine.where("command_id = ?",cmd.id).first
#    line = CommandLine.where("command_id = ? and external_info = ?",cmd.id, ext_info).first

    # do the checks

    expect(cmd.crop_id       ).to eq(crop_id      )
    expect(line.action       ).to eq(action       )
    expect(line.external_info).to eq(ext_info     )
    expect(line.coord_x      ).to eq(x            )
    expect(line.coord_y      ).to eq(y            )
    expect(line.coord_z      ).to eq(z            )
    expect(line.speed        ).to eq(speed        )
    expect(line.amount       ).to eq(amount       )
    expect(line.pin_nr       ).to eq(pin_nr       )
    expect(line.pin_value_1  ).to eq(pin_value1   )
    expect(line.pin_value_2  ).to eq(pin_value2   )
    expect(line.pin_mode     ).to eq(pin_mode     )
    expect(line.pin_time     ).to eq(pin_time     )

  end

  it "save single command" do

    # create new command data

    sched_time    = Time.now
    crop_id       = rand(9999999).to_i
    action        = rand(9999999).to_s
    x             = rand(9999999).to_i
    y             = rand(9999999).to_i
    z             = rand(9999999).to_i
    speed         = rand(9999999).to_s
    amount        = rand(9999999).to_i
    pin_nr        = rand(9999999).to_i
    pin_value1    = rand(9999999).to_i
    pin_value2    = rand(9999999).to_i
    pin_mode      = rand(9999999).to_i
    pin_time      = rand(9999999).to_i
    ext_info      = rand(9999999).to_s
    delay         = rand(     99).to_i + 10

    # save the new command in the database

    command =
      {
        'action'        => action        ,
        'delay'         => delay         ,
        'x'             => x             ,
        'y'             => y             ,
        'z'             => z             ,
        'speed'         => speed         ,
        'amount'        => amount        ,
        'pin'           => pin_nr        ,
        'value1'        => pin_value1    ,
        'value2'        => pin_value2    ,
        'mode'          => pin_mode      ,
        'time'          => pin_time      ,
        'info'          => ext_info
      }

    command_obj = MessageHandlerScheduleCmdLine.new
    command_obj.split_command_line(command)

    @handler.save_single_command(command_obj,  delay)

    # get the data back from the database

    cmd = Command.where("scheduled_time >= ?",sched_time + 10).last
    line = CommandLine.where("command_id = ?",cmd.id).first

    # do the checks

    expect(line.action       ).to eq(action       )
    expect(line.external_info).to eq(ext_info     )
    expect(line.coord_x      ).to eq(x            )
    expect(line.coord_y      ).to eq(y            )
    expect(line.coord_z      ).to eq(z            )
    expect(line.speed        ).to eq(speed        )
    expect(line.amount       ).to eq(amount       )
    expect(line.pin_nr       ).to eq(pin_nr       )
    expect(line.pin_value_1  ).to eq(pin_value1   )
    expect(line.pin_value_2  ).to eq(pin_value2   )
    expect(line.pin_mode     ).to eq(pin_mode     )
    expect(line.pin_time     ).to eq(pin_time     )

  end

  it "handle single command" do

    # create new command data

    sched_time    = Time.now
    crop_id       = rand(9999999).to_i
    action        = rand(9999999).to_s
    x             = rand(9999999).to_i
    y             = rand(9999999).to_i
    z             = rand(9999999).to_i
    speed         = rand(9999999).to_s
    amount        = rand(9999999).to_i
    pin_nr        = rand(9999999).to_i
    pin_value1    = rand(9999999).to_i
    pin_value2    = rand(9999999).to_i
    pin_mode      = rand(9999999).to_i
    pin_time      = rand(9999999).to_i
    ext_info      = rand(9999999).to_s
    delay         = rand(     99).to_i

    # create a message

    message = MessageHandlerMessage.new
    message.handled = false
    message.handler = @main_handler
    message.payload =
      {
        'command'  =>
        {
          'delay'  => delay      ,
          'action' => action     ,
          'x'      => x          ,
          'y'      => y          ,
          'z'      => z          ,
          'speed'  => speed      ,
          'amount' => amount     ,
          'pin'    => pin_nr     ,
          'value1' => pin_value1 ,
          'value2' => pin_value2 ,
          'mode'   => pin_mode   ,
          'time'   => pin_time   ,
          'info'   => ext_info
        }
      }

    # execute the message

    @handler.single_command(message)

    # get the data back from the database

    cmd = Command.where("scheduled_time >= ?",sched_time).last
    line = CommandLine.where("command_id = ?",cmd.id).first

    # do the checks

    expect(line.action       ).to eq(action       )
    expect(line.external_info).to eq(ext_info     )
    expect(line.coord_x      ).to eq(x            )
    expect(line.coord_y      ).to eq(y            )
    expect(line.coord_z      ).to eq(z            )
    expect(line.speed        ).to eq(speed        )
    expect(line.amount       ).to eq(amount       )
    expect(line.pin_nr       ).to eq(pin_nr       )
    expect(line.pin_value_1  ).to eq(pin_value1   )
    expect(line.pin_value_2  ).to eq(pin_value2   )
    expect(line.pin_mode     ).to eq(pin_mode     )
    expect(line.pin_time     ).to eq(pin_time     )

  end

  it "handle empty command" do

    # create a message

    message = MessageHandlerMessage.new
    message.handled = false
    message.handler = @main_handler
    message.payload = {}

    # execute the message

    @handler.single_command(message)

    # do the checks

    expect(@handler.messaging.message[:message_type]).to eq('error')

  end

# save_command_with_lines

  it "save command with lines" do

    # create new command data

    sched_time      = Time.now
    crop_id         = rand(9999999).to_i

    action_A        = rand(9999999).to_s
    x_A             = rand(9999999).to_i
    y_A             = rand(9999999).to_i
    z_A             = rand(9999999).to_i
    speed_A         = rand(9999999).to_s
    amount_A        = rand(9999999).to_i
    pin_nr_A        = rand(9999999).to_i
    pin_value1_A    = rand(9999999).to_i
    pin_value2_A    = rand(9999999).to_i
    pin_mode_A      = rand(9999999).to_i
    pin_time_A      = rand(9999999).to_i
    ext_info_A      = rand(9999999).to_s
    delay_A         = rand(     99).to_i

    action_B        = rand(9999999).to_s
    x_B             = rand(9999999).to_i
    y_B             = rand(9999999).to_i
    z_B             = rand(9999999).to_i
    speed_B         = rand(9999999).to_s
    amount_B        = rand(9999999).to_i
    pin_nr_B        = rand(9999999).to_i
    pin_value1_B    = rand(9999999).to_i
    pin_value2_B    = rand(9999999).to_i
    pin_mode_B      = rand(9999999).to_i
    pin_time_B      = rand(9999999).to_i
    ext_info_B      = rand(9999999).to_s
    delay_B         = rand(     99).to_i

    # create a command

    command =
      {
        'scheduled_time' => sched_time.utc.to_s,
        'crop_id'        => crop_id        ,
        'command_lines'  =>
        [
          {
            'delay'  => delay_A      ,
            'action' => action_A     ,
            'x'      => x_A          ,
            'y'      => y_A          ,
            'z'      => z_A          ,
            'speed'  => speed_A      ,
            'amount' => amount_A     ,
            'pin'    => pin_nr_A     ,
            'value1' => pin_value1_A ,
            'value2' => pin_value2_A ,
            'mode'   => pin_mode_A   ,
            'time'   => pin_time_A   ,
            'info'   => ext_info_A
          },
          {
            'delay'  => delay_B      ,
            'action' => action_B     ,
            'x'      => x_B          ,
            'y'      => y_B          ,
            'z'      => z_B          ,
            'speed'  => speed_B      ,
            'amount' => amount_B     ,
            'pin'    => pin_nr_B     ,
            'value1' => pin_value1_B ,
            'value2' => pin_value2_B ,
            'mode'   => pin_mode_B   ,
            'time'   => pin_time_B   ,
            'info'   => ext_info_B
          }
        ]
      }

    # execute the message

    @handler.save_command_with_lines(command)

    # get the data back from the database

    cmd = Command.where("crop_id = ?",crop_id).first
    line_A = CommandLine.where("command_id = ?",cmd.id).first
    line_B = CommandLine.where("command_id = ?",cmd.id).last

    nr_of_lines = CommandLine.where("command_id = ?",cmd.id).count


    # do the checks

    expect(nr_of_lines         ).to eq(2              )

    expect(line_A.action       ).to eq(action_A       )
    expect(line_A.external_info).to eq(ext_info_A     )
    expect(line_A.coord_x      ).to eq(x_A            )
    expect(line_A.coord_y      ).to eq(y_A            )
    expect(line_A.coord_z      ).to eq(z_A            )
    expect(line_A.speed        ).to eq(speed_A        )
    expect(line_A.amount       ).to eq(amount_A       )
    expect(line_A.pin_nr       ).to eq(pin_nr_A       )
    expect(line_A.pin_value_1  ).to eq(pin_value1_A   )
    expect(line_A.pin_value_2  ).to eq(pin_value2_A   )
    expect(line_A.pin_mode     ).to eq(pin_mode_A     )
    expect(line_A.pin_time     ).to eq(pin_time_A     )

    expect(line_B.action       ).to eq(action_B       )
    expect(line_B.external_info).to eq(ext_info_B     )
    expect(line_B.coord_x      ).to eq(x_B            )
    expect(line_B.coord_y      ).to eq(y_B            )
    expect(line_B.coord_z      ).to eq(z_B            )
    expect(line_B.speed        ).to eq(speed_B        )
    expect(line_B.amount       ).to eq(amount_B       )
    expect(line_B.pin_nr       ).to eq(pin_nr_B       )
    expect(line_B.pin_value_1  ).to eq(pin_value1_B   )
    expect(line_B.pin_value_2  ).to eq(pin_value2_B   )
    expect(line_B.pin_mode     ).to eq(pin_mode_B     )
    expect(line_B.pin_time     ).to eq(pin_time_B     )

  end

  it "crop schedule update" do

    # create new command data

    sched_time_AB    = Time.now
    crop_id_AB       = rand(9999999).to_i

    action_A        = rand(9999999).to_s
    x_A             = rand(9999999).to_i
    y_A             = rand(9999999).to_i
    z_A             = rand(9999999).to_i
    speed_A         = rand(9999999).to_s
    amount_A        = rand(9999999).to_i
    pin_nr_A        = rand(9999999).to_i
    pin_value1_A    = rand(9999999).to_i
    pin_value2_A    = rand(9999999).to_i
    pin_mode_A      = rand(9999999).to_i
    pin_time_A      = rand(9999999).to_i
    ext_info_A      = rand(9999999).to_s
    delay_A         = rand(     99).to_i

    action_B        = rand(9999999).to_s
    x_B             = rand(9999999).to_i
    y_B             = rand(9999999).to_i
    z_B             = rand(9999999).to_i
    speed_B         = rand(9999999).to_s
    amount_B        = rand(9999999).to_i
    pin_nr_B        = rand(9999999).to_i
    pin_value1_B    = rand(9999999).to_i
    pin_value2_B    = rand(9999999).to_i
    pin_mode_B      = rand(9999999).to_i
    pin_time_B      = rand(9999999).to_i
    ext_info_B      = rand(9999999).to_s
    delay_B         = rand(     99).to_i

    sched_time_CD    = Time.now
    crop_id_CD       = rand(9999999).to_i

    action_C        = rand(9999999).to_s
    x_C             = rand(9999999).to_i
    y_C             = rand(9999999).to_i
    z_C             = rand(9999999).to_i
    speed_C         = rand(9999999).to_s
    amount_C        = rand(9999999).to_i
    pin_nr_C        = rand(9999999).to_i
    pin_value1_C    = rand(9999999).to_i
    pin_value2_C    = rand(9999999).to_i
    pin_mode_C      = rand(9999999).to_i
    pin_time_C      = rand(9999999).to_i
    ext_info_C      = rand(9999999).to_s
    delay_C         = rand(     99).to_i

    action_D        = rand(9999999).to_s
    x_D             = rand(9999999).to_i
    y_D             = rand(9999999).to_i
    z_D             = rand(9999999).to_i
    speed_D         = rand(9999999).to_s
    amount_D        = rand(9999999).to_i
    pin_nr_D        = rand(9999999).to_i
    pin_value1_D    = rand(9999999).to_i
    pin_value2_D    = rand(9999999).to_i
    pin_mode_D      = rand(9999999).to_i
    pin_time_D      = rand(9999999).to_i
    ext_info_D      = rand(9999999).to_s
    delay_D         = rand(     99).to_i


    # create a command

    message = MessageHandlerMessage.new
    message.handled = false
    message.handler = @main_handler
    message.payload =
      {
        'commands' =>
        [
          {
            'scheduled_time' => sched_time_AB.utc.to_s,
            'crop_id'        => crop_id_AB        ,
            'command_lines'  =>
            [
              {
                'delay'  => delay_A      ,
                'action' => action_A     ,
                'x'      => x_A          ,
                'y'      => y_A          ,
                'z'      => z_A          ,
                'speed'  => speed_A      ,
                'amount' => amount_A     ,
                'pin'    => pin_nr_A     ,
                'value1' => pin_value1_A ,
                'value2' => pin_value2_A ,
                'mode'   => pin_mode_A   ,
                'time'   => pin_time_A   ,
                'info'   => ext_info_A
              },
              {
                'delay'  => delay_B      ,
                'action' => action_B     ,
                'x'      => x_B          ,
                'y'      => y_B          ,
                'z'      => z_B          ,
                'speed'  => speed_B      ,
                'amount' => amount_B     ,
                'pin'    => pin_nr_B     ,
                'value1' => pin_value1_B ,
                'value2' => pin_value2_B ,
                'mode'   => pin_mode_B   ,
                'time'   => pin_time_B   ,
                'info'   => ext_info_B
              }
            ]
          },
          {
            'scheduled_time' => sched_time_CD.utc.to_s,
            'crop_id'        => crop_id_CD            ,
            'command_lines'  =>
            [
              {
                'delay'  => delay_C      ,
                'action' => action_C     ,
                'x'      => x_C          ,
                'y'      => y_C          ,
                'z'      => z_C          ,
                'speed'  => speed_C      ,
                'amount' => amount_C     ,
                'pin'    => pin_nr_C     ,
                'value1' => pin_value1_C ,
                'value2' => pin_value2_C ,
                'mode'   => pin_mode_C   ,
                'time'   => pin_time_C   ,
                'info'   => ext_info_C
              },
              {
                'delay'  => delay_D      ,
                'action' => action_D     ,
                'x'      => x_D          ,
                'y'      => y_D          ,
                'z'      => z_D          ,
                'speed'  => speed_D      ,
                'amount' => amount_D     ,
                'pin'    => pin_nr_D     ,
                'value1' => pin_value1_D ,
                'value2' => pin_value2_D ,
                'mode'   => pin_mode_D   ,
                'time'   => pin_time_D   ,
                'info'   => ext_info_D
              }
            ]
          }
        ]
      }

    # execute the message

    @handler.crop_schedule_update(message)

    # get the data back from the database

    cmd_AB = Command.where("crop_id = ?",crop_id_AB).first
    line_A = CommandLine.where("command_id = ?",cmd_AB.id).first
    line_B = CommandLine.where("command_id = ?",cmd_AB.id).last

    nr_of_lines_AB = CommandLine.where("command_id = ?",cmd_AB.id).count

    cmd_CD = Command.where("crop_id = ?",crop_id_CD).first
    line_C = CommandLine.where("command_id = ?",cmd_CD.id).first
    line_D = CommandLine.where("command_id = ?",cmd_CD.id).last

    nr_of_lines_CD = CommandLine.where("command_id = ?",cmd_CD.id).count

    # do the checks

    expect(nr_of_lines_AB      ).to eq(2              )

    expect(line_A.action       ).to eq(action_A       )
    expect(line_A.external_info).to eq(ext_info_A     )
    expect(line_A.coord_x      ).to eq(x_A            )
    expect(line_A.coord_y      ).to eq(y_A            )
    expect(line_A.coord_z      ).to eq(z_A            )
    expect(line_A.speed        ).to eq(speed_A        )
    expect(line_A.amount       ).to eq(amount_A       )
    expect(line_A.pin_nr       ).to eq(pin_nr_A       )
    expect(line_A.pin_value_1  ).to eq(pin_value1_A   )
    expect(line_A.pin_value_2  ).to eq(pin_value2_A   )
    expect(line_A.pin_mode     ).to eq(pin_mode_A     )
    expect(line_A.pin_time     ).to eq(pin_time_A     )

    expect(line_B.action       ).to eq(action_B       )
    expect(line_B.external_info).to eq(ext_info_B     )
    expect(line_B.coord_x      ).to eq(x_B            )
    expect(line_B.coord_y      ).to eq(y_B            )
    expect(line_B.coord_z      ).to eq(z_B            )
    expect(line_B.speed        ).to eq(speed_B        )
    expect(line_B.amount       ).to eq(amount_B       )
    expect(line_B.pin_nr       ).to eq(pin_nr_B       )
    expect(line_B.pin_value_1  ).to eq(pin_value1_B   )
    expect(line_B.pin_value_2  ).to eq(pin_value2_B   )
    expect(line_B.pin_mode     ).to eq(pin_mode_B     )
    expect(line_B.pin_time     ).to eq(pin_time_B     )

    expect(nr_of_lines_CD      ).to eq(2              )

    expect(line_C.action       ).to eq(action_C       )
    expect(line_C.external_info).to eq(ext_info_C     )
    expect(line_C.coord_x      ).to eq(x_C            )
    expect(line_C.coord_y      ).to eq(y_C            )
    expect(line_C.coord_z      ).to eq(z_C            )
    expect(line_C.speed        ).to eq(speed_C        )
    expect(line_C.amount       ).to eq(amount_C       )
    expect(line_C.pin_nr       ).to eq(pin_nr_C       )
    expect(line_C.pin_value_1  ).to eq(pin_value1_C   )
    expect(line_C.pin_value_2  ).to eq(pin_value2_C   )
    expect(line_C.pin_mode     ).to eq(pin_mode_C     )
    expect(line_C.pin_time     ).to eq(pin_time_C     )

    expect(line_D.action       ).to eq(action_D       )
    expect(line_D.external_info).to eq(ext_info_D     )
    expect(line_D.coord_x      ).to eq(x_D            )
    expect(line_D.coord_y      ).to eq(y_D            )
    expect(line_D.coord_z      ).to eq(z_D            )
    expect(line_D.speed        ).to eq(speed_D        )
    expect(line_D.amount       ).to eq(amount_D       )
    expect(line_D.pin_nr       ).to eq(pin_nr_D       )
    expect(line_D.pin_value_1  ).to eq(pin_value1_D   )
    expect(line_D.pin_value_2  ).to eq(pin_value2_D   )
    expect(line_D.pin_mode     ).to eq(pin_mode_D     )
    expect(line_D.pin_time     ).to eq(pin_time_D     )

  end

end

require 'spec_helper'
require './lib/status.rb'
require './lib/handlers/messagehandler.rb'
require './lib/handlers/messagehandler_base.rb'
require './lib/handlers/messagehandler_status.rb'
require './spec/fixtures/stub_messenger.rb'

class HwStatusSim
  def read_hw_status
  end
end

describe MessageHandlerStatus do
  let(:message) { MessageHandlerMessage.new({}, StubMessenger.new) }

  before do
    DbAccess.current = DbAccess.new('development')
    DbAccess.current = DbAccess.current
    DbAccess.current.disable_log_to_screen()

    Status.current = Status.new

    $bot_control = HwStatusSim.new

    messaging = StubMessenger.new
    messaging.reset

    @handler = MessageHandlerStatus.new(messaging)
    @main_handler = MessageHandler.new(messaging)
  end

  it "white list" do
    list = @handler.whitelist
    expect(list.count).to eq(1)
  end


  it "read status" do

    # create new status data

    message_type                   = 'read_status_response',
    time_stamp                     = Time.now.to_f.to_s,
    confirm_id                     = rand(9999999).to_s

    status                         = rand(9999999).to_s
    status_time_local              = Time.now
    status_nr_msg_received         = rand(9999999).to_i
    status_movement                = rand(9999999).to_s
    status_last_command_executed   = rand(9999999).to_s
    status_next_command_scheduled  = rand(9999999).to_s
    status_nr_of_commands_executed = rand(9999999).to_i
    status_current_x               = rand(9999999).to_i
    status_current_y               = rand(9999999).to_i
    status_current_z               = rand(9999999).to_i
    status_target_x                = rand(9999999).to_i
    status_target_y                = rand(9999999).to_i
    status_target_z                = rand(9999999).to_i
    status_end_stop_x_a            = rand(9999999).to_i
    status_end_stop_x_b            = rand(9999999).to_i
    status_end_stop_y_a            = rand(9999999).to_i
    status_end_stop_y_b            = rand(9999999).to_i
    status_end_stop_z_a            = rand(9999999).to_i
    status_end_stop_z_b            = rand(9999999).to_i


    Status.current.info_status         = status
    $info_nr_msg_received       = status_nr_msg_received
    Status.current.info_movement       = status_movement
    Status.current.info_command_last   = status_last_command_executed
    Status.current.info_command_next   = status_next_command_scheduled
    Status.current.info_nr_of_commands = status_nr_of_commands_executed
    Status.current.info_current_x      = status_current_x
    Status.current.info_current_y      = status_current_y
    Status.current.info_current_z      = status_current_z
    Status.current.info_target_x       = status_target_x
    Status.current.info_target_y       = status_target_y
    Status.current.info_target_z       = status_target_z
    Status.current.info_end_stop_x_a   = status_end_stop_x_a
    Status.current.info_end_stop_x_b   = status_end_stop_x_b
    Status.current.info_end_stop_y_a   = status_end_stop_y_a
    Status.current.info_end_stop_y_b   = status_end_stop_y_b
    Status.current.info_end_stop_z_a   = status_end_stop_z_a
    Status.current.info_end_stop_z_b   = status_end_stop_z_b


    # create a message

    message.time_stamp = confirm_id
    message.handled    = false
    message.handler    = @main_handler

    # handle message

    @handler.read_status(message)

    # retrieve response message

    return_msg = @handler.messaging.message

    # do the checks

    expect(return_msg[:time_stamp].length              ).to be > 10
    expect(return_msg[:status_time_local]              ).to be > status_time_local
    expect(return_msg[:message_type]                   ).to eq('read_status_response')
    expect(return_msg[:confirm_id]                     ).to eq(confirm_id)
    expect(return_msg[:status]                         ).to eq(status)
    expect(return_msg[:status_nr_msg_received]         ).to eq(status_nr_msg_received)
    expect(return_msg[:status_movement]                ).to eq(status_movement)
    expect(return_msg[:status_last_command_executed]   ).to eq(status_last_command_executed)
    expect(return_msg[:status_next_command_scheduled]  ).to eq(status_next_command_scheduled)
    expect(return_msg[:status_nr_of_commands_executed] ).to eq(status_nr_of_commands_executed)
    expect(return_msg[:status_current_x]               ).to eq(status_current_x)
    expect(return_msg[:status_current_y]               ).to eq(status_current_y)
    expect(return_msg[:status_current_z]               ).to eq(status_current_z)
    expect(return_msg[:status_target_x]                ).to eq(status_target_x)
    expect(return_msg[:status_target_y]                ).to eq(status_target_y)
    expect(return_msg[:status_target_z]                ).to eq(status_target_z)
    expect(return_msg[:status_end_stop_x_a]            ).to eq(status_end_stop_x_a)
    expect(return_msg[:status_end_stop_x_b]            ).to eq(status_end_stop_x_b)
    expect(return_msg[:status_end_stop_y_a]            ).to eq(status_end_stop_y_a)
    expect(return_msg[:status_end_stop_y_b]            ).to eq(status_end_stop_y_b)
    expect(return_msg[:status_end_stop_z_a]            ).to eq(status_end_stop_z_a)
    expect(return_msg[:status_end_stop_z_b]            ).to eq(status_end_stop_z_b)

  end


end

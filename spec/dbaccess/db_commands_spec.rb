require 'spec_helper'
require './lib/database/dbaccess.rb'

describe DbAccess do

  before do
    @db = DbAccess.new('development')
  end

  ## commands

  it "create new command" do
    crop_id        = rand(9999999).to_i
    scheduled_time = Time.now

    @db.create_new_command(scheduled_time, crop_id)

    cmd = Command.where("scheduled_time = ?",scheduled_time).first

    expect(cmd.crop_id).to eq(crop_id)
  end


  it "add command line" do

    crop_id        = rand(9999999).to_i
    scheduled_time = Time.now

    action        = "TEST"
    x             = rand(9999999).to_i
    y             = rand(9999999).to_i
    z             = rand(9999999).to_i
    speed         = rand(9999999).to_s
    amount        = rand(9999999).to_i
    pin_nr        = rand(9999999).to_i
    value1        = rand(9999999).to_i
    value2        = rand(9999999).to_i
    mode          = rand(9999999).to_i
    time          = rand(9999999).to_i
    external_info = Time.now.to_s

    @db.create_new_command(scheduled_time, crop_id)
    @db.add_command_line(action, x, y, z, speed, amount, pin_nr, value1, value2, mode, time, external_info)

    cmd = Command.where("scheduled_time = ?",scheduled_time).first
    line = CommandLine.where("command_id = ? and external_info = ?",cmd.id, external_info).first

    expect(line.action       ).to eq(action       )
    expect(line.external_info).to eq(external_info)
    expect(line.coord_x      ).to eq(x            )
    expect(line.coord_y      ).to eq(y            )
    expect(line.coord_z      ).to eq(z            )
    expect(line.speed        ).to eq(speed        )
    expect(line.amount       ).to eq(amount       )
    expect(line.pin_nr       ).to eq(pin_nr       )
    expect(line.pin_value_1  ).to eq(value1       )
    expect(line.pin_value_2  ).to eq(value2       )
    expect(line.pin_mode     ).to eq(mode         )
    expect(line.pin_time     ).to eq(time         )

  end

  it "fill in command line coordinates" do

    action        = "TEST"
    x             = rand(9999999).to_i
    y             = rand(9999999).to_i
    z             = rand(9999999).to_i
    speed         = rand(9999999).to_s

    line = CommandLine.new
    @db.fill_in_command_line_coordinates(line, action, x, y, z, speed)

    expect(line.action       ).to eq(action       )
    expect(line.coord_x      ).to eq(x            )
    expect(line.coord_y      ).to eq(y            )
    expect(line.coord_z      ).to eq(z            )
    expect(line.speed        ).to eq(speed        )

  end

  it "fill in command line pins" do


    pin_nr  = rand(9999999).to_i
    value1  = rand(9999999).to_i
    value2  = rand(9999999).to_i
    mode    = rand(9999999).to_i
    time    = rand(9999999).to_i

    line = CommandLine.new
    @db.fill_in_command_line_pins(line, pin_nr, value1, value2, mode, time)

    expect(line.pin_nr      ).to eq(pin_nr       )
    expect(line.pin_value_1 ).to eq(value1       )
    expect(line.pin_value_2 ).to eq(value2       )
    expect(line.pin_mode    ).to eq(mode         )
    expect(line.pin_time    ).to eq(time         )

  end

  it "fill in command line extra" do

    amount        = rand(9999999).to_i
    external_info = rand(9999999).to_s

    crop_id        = rand(9999999).to_i
    scheduled_time = Time.now

    @db.create_new_command(scheduled_time, crop_id)

    line = CommandLine.new
    @db.fill_in_command_line_extra(line, amount, external_info)

    expect(line.amount       ).to eq(amount       )
    expect(line.external_info).to eq(external_info)

  end

  it "save new command" do

    crop_id        = rand(9999999).to_i
    scheduled_time = Time.now

    @db.create_new_command(scheduled_time, crop_id)

    line = CommandLine.new
    @db.save_new_command

    cmd = Command.where("scheduled_time = ?",scheduled_time).first

    expect(cmd.crop_id).to eq(crop_id)
  end

  it "clear schedule" do

    line = CommandLine.new
    @db.clear_schedule

    cmd = Command.where("status = ? AND scheduled_time IS NOT NULL",'scheduled').count

    expect(cmd).to eq(0)
  end


  it "clear crop schedule" do

    crop_id_1      = rand(9999999).to_i
    crop_id_2      = rand(9999999).to_i
    scheduled_time = Time.now

    @db.create_new_command(scheduled_time, crop_id_1)
    @db.save_new_command

    @db.create_new_command(scheduled_time, crop_id_2)
    @db.save_new_command

    @db.clear_crop_schedule(crop_id_1)

    cmd_1 = Command.where("scheduled_time = ? AND crop_id = ?",scheduled_time,crop_id_1).count
    cmd_2 = Command.where("scheduled_time = ? AND crop_id = ?",scheduled_time,crop_id_2).count

    expect(cmd_1).to eq(0)
    expect(cmd_2).to eq(1)
  end


  it "clear crop schedule" do

    crop_id        = rand(9999999).to_i
    scheduled_time = Time.now

    @db.create_new_command(scheduled_time, crop_id)
    @db.save_new_command

    cmd = @db.get_command_to_execute()


    expect(cmd).not_to be_nil
  end

  it "set command to exeute status" do

    crop_id        = rand(9999999).to_i
    scheduled_time = Time.now

    @db.create_new_command(scheduled_time, crop_id)
    @db.save_new_command

    cmd = @db.get_command_to_execute()
    @db.set_command_to_execute_status("TEST")

    cmd_changed = Command.where("id = ?",cmd.id).first


    expect(cmd_changed.status).to eq("TEST")
  end

end

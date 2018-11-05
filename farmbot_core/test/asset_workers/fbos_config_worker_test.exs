defmodule Farmbot.FbosConfigWorkerTest do
  use ExUnit.Case
  alias Farmbot.Asset.FbosConfig

  test "adds configs to bot state and config_storage" do
    conf = FbosConfig.changeset(%FbosConfig{}, %{
      arduino_debug_messages: true,
      auto_sync: false,
      beta_opt_in: true,
      disable_factory_reset: false,
      firmware_hardware: "farmduino_k14",
      firmware_input_log: false,
      firmware_output_log: false,
      id: 145,
      network_not_found_timer: nil,
      os_auto_update: false,
      sequence_body_log: true,
      sequence_complete_log: true,
      sequence_init_log: true,
    }) |> Farmbot.Asset.Repo.insert!()

    :ok = Farmbot.AssetMonitor.force_checkup()

    # Wait for the timeout to be dispatched
    Process.sleep(100)

    state_conf = Farmbot.BotState.fetch().configuration
    assert state_conf.arduino_debug_messages == conf.arduino_debug_messages
    assert state_conf.auto_sync == conf.auto_sync
    assert state_conf.beta_opt_in == conf.beta_opt_in
    assert state_conf.disable_factory_reset == conf.disable_factory_reset
    assert state_conf.firmware_hardware == conf.firmware_hardware
    assert state_conf.firmware_input_log == conf.firmware_input_log
    assert state_conf.firmware_output_log == conf.firmware_output_log
    assert state_conf.network_not_found_timer == conf.network_not_found_timer
    assert state_conf.os_auto_update == conf.os_auto_update
    assert state_conf.sequence_body_log == conf.sequence_body_log
    assert state_conf.sequence_complete_log == conf.sequence_complete_log
    assert state_conf.sequence_init_log == conf.sequence_init_log

    # TODO(Connor) assert config_storage
  end
end

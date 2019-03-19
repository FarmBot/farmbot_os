defmodule FarmbotCore.FbosConfigWorkerTest do
  use ExUnit.Case, async: true
  alias FarmbotCore.{Asset.FbosConfig, AssetWorker, BotState}

  import Farmbot.TestSupport.AssetFixtures

  test "adds configs to bot state and config_storage" do
    %FbosConfig{} =
      conf =
      fbos_config(%{
        monitor: true,
        arduino_debug_messages: true,
        auto_sync: false,
        beta_opt_in: true,
        disable_factory_reset: false,
        firmware_hardware: "farmduino_k14",
        firmware_input_log: false,
        firmware_output_log: false,
        network_not_found_timer: nil,
        os_auto_update: false,
        sequence_body_log: true,
        sequence_complete_log: true,
        sequence_init_log: true
      })

    {:ok, pid} = AssetWorker.start_link(conf)
    send(pid, :timeout)

    state = BotState.subscribe()

    state_conf = receive_changes(state).configuration
    assert state_conf.arduino_debug_messages == conf.arduino_debug_messages
    assert state_conf.auto_sync == conf.auto_sync
    assert state_conf.beta_opt_in == conf.beta_opt_in
    assert state_conf.disable_factory_reset == conf.disable_factory_reset

    # The TTYDetector actually will set this value
    # only if the state actually changes properly.
    # assert state_conf.firmware_hardware == conf.firmware_hardware

    assert state_conf.firmware_input_log == conf.firmware_input_log
    assert state_conf.firmware_output_log == conf.firmware_output_log
    assert state_conf.network_not_found_timer == conf.network_not_found_timer
    assert state_conf.os_auto_update == conf.os_auto_update
    assert state_conf.sequence_body_log == conf.sequence_body_log
    assert state_conf.sequence_complete_log == conf.sequence_complete_log
    assert state_conf.sequence_init_log == conf.sequence_init_log

    # TODO(Connor) assert config_storage
  end

  def receive_changes(state) do
    receive do
      {BotState, %{changes: %{configuration: _}} = change} ->
        Ecto.Changeset.apply_changes(change)
        |> receive_changes()

      _ ->
        receive_changes(state)
    after
      100 ->
        state
    end
  end
end

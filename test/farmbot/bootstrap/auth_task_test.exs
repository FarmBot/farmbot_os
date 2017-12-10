defmodule Farmbot.Bootstrap.AuthTaskTest do
  @moduledoc "Tests the timed token refresher"

  alias Farmbot.Bootstrap.AuthTask
  alias Farmbot.System.ConfigStorage
  use ExUnit.Case, async: true
  @moduletag :farmbot_api

  setup do
    # This is usally a timed task. Cancel the timer, so we can
    # simulate the timer firing.
    timer = :sys.get_state(AuthTask)
    if Process.read_timer(timer) do
      Process.cancel_timer(timer)
    end
    :ok
  end

  test "refreshes token and causes side effects" do
    old_tps = Process.whereis Farmbot.BotState.Transport.Supervisor
    old_token = ConfigStorage.get_config_value(:string, "authorization", "token")
    send AuthTask, :refresh

    # I'm sorry about this.
    Process.sleep(1000)

    new_tps = Process.whereis Farmbot.BotState.Transport.Supervisor
    new_token = ConfigStorage.get_config_value(:string, "authorization", "token")
    assert old_tps != new_tps
    assert new_token != old_token

    # check that the timer refreshed itself.
    assert :sys.get_state(AuthTask)
  end


end

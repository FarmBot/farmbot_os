defmodule FarmbotCore.Private.EnigmaWorkerTest do
  use ExUnit.Case, async: true
  alias FarmbotCore.{BotState, EnigmaHandler, Asset.Private.Enigma, AssetWorker}

  test "enigmas existance is persisted to the bot's state" do
    Process.flag(:trap_exit, true)
    uuid = Ecto.UUID.generate()

    enigma = %Enigma{
      local_id: uuid,
      priority: 100,
      created_at: DateTime.utc_now()
    }

    bot_state = BotState.subscribe()

    # Ensures this enigma hasn't been registered yet somehow
    refute bot_state.enigmas[uuid]

    # Start the enigma manager process
    {:ok, pid} = AssetWorker.start_link(enigma)

    # Ensure it was added
    assert_receive {BotState, %{changes: %{enigmas: enigmas}}}
    assert enigmas[uuid].priority == 100

    # Stop the enigma
    :ok = GenServer.stop(pid)

    # Ensure it was actually stopped
    assert_receive {:EXIT, ^pid, :normal}
    refute Process.alive?(pid)

    # Ensure the enigma was removed from the state
    assert_receive {BotState, %{changes: %{enigmas: enigmas}}}
    refute enigmas[uuid]
  end

  test "enigmas lifecycle events" do
    uuid = Ecto.UUID.generate()

    enigma = %Enigma{
      local_id: uuid,
      priority: 100,
      created_at: DateTime.utc_now(),
      problem_tag: "hello.world"
    }

    test_pid = self()

    up_fun = fn _ ->
      send(test_pid, :up)
      {:error, "reason"}
    end

    down_fun = fn _ ->
      send(test_pid, :down)
      :ok
    end

    EnigmaHandler.register_up("hello.world", up_fun)
    EnigmaHandler.register_down("hello.world", down_fun)

    {:ok, pid} = AssetWorker.start_link(enigma)

    assert_receive :up

    # Stop the enigma
    Process.flag(:trap_exit, true)
    :ok = GenServer.stop(pid)
    assert_receive {:EXIT, ^pid, :normal}
    refute Process.alive?(pid)

    assert_receive :down
  end
end

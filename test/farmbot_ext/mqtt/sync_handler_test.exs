defmodule FarmbotOS.SyncHandlerTest do
  use ExUnit.Case
  use Mimic

  alias FarmbotOS.MQTT.{
    SyncHandler,
    SyncHandlerSupport
  }

  setup :set_mimic_global
  setup :verify_on_exit!

  test "process startup lifecycle" do
    expect1 = %SyncHandler{
      client_id: "test_client_id",
      preloaded: false,
      username: "test_username"
    }

    expect(SyncHandlerSupport, :preload_all, 1, fn s -> {:noreply, s} end)
    expect(SyncHandlerSupport, :drop_all_cache, 1, fn -> :ok end)

    args = [client_id: expect1.client_id, username: expect1.username]
    {:ok, pid} = SyncHandler.start_link(args, [])
    actual_state = :sys.get_state(pid)
    assert actual_state == expect1
    # Ensure `handle_info` accepts garbage.
    send(pid, "DLKFJSLKJDFJKDSF")
    send(pid, {:inbound, [], "{}"})
    _ = Process.unlink(pid)
    :ok = GenServer.stop(pid, :normal, 3_000)
  end

  test "process lifecycle - preload" do
    expect1 = %SyncHandler{
      client_id: "test_client_id",
      preloaded: false,
      username: "test_username"
    }

    expect(SyncHandlerSupport, :preload_all, 1, fn state ->
      {:noreply, %{state | preloaded: true}}
    end)

    expect(SyncHandlerSupport, :reply_to_sync_message, 1, fn _, _, _, _ ->
      :ok
    end)

    expect(SyncHandlerSupport, :drop_all_cache, 1, fn -> :ok end)

    args = [client_id: expect1.client_id, username: expect1.username]
    {:ok, pid} = SyncHandler.start_link(args, [])
    actual_state = :sys.get_state(pid)
    assert actual_state.preloaded
    msg = {:inbound, ["bot", "device_1", "sync", "Point", "1"], "{}"}
    send(pid, msg)
    _ = Process.unlink(pid)
    :ok = GenServer.stop(pid, :normal, 3_000)
  end
end

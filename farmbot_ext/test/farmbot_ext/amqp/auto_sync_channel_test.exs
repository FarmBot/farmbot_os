defmodule AutoSyncChannelTest do
  require Helpers
  use ExUnit.Case, async: false
  use Mimic
  alias FarmbotExt.AMQP.AutoSyncChannel

  alias FarmbotExt.{
    AMQP.ConnectionWorker,
    API.Preloader,
    JWT
  }

  setup :verify_on_exit!
  setup :set_mimic_global

  @fake_jwt Helpers.fake_jwt()

  def generate_pid do
    apply_default_mocks()
    jwt = JWT.decode!(@fake_jwt)
    {:ok, pid} = AutoSyncChannel.start_link([jwt: jwt], [])
    pid
  end

  def apply_default_mocks do
    ok1 = fn _ -> :whatever end
    stub(FarmbotExt.API.EagerLoader.Supervisor, :drop_all_cache, fn -> :ok end)
    stub(ConnectionWorker, :close_channel, ok1)

    stub(ConnectionWorker, :maybe_connect_autosync, fn _ ->
      %{conn: %{fake_conn: true}, chan: %{fake_chan: true}}
    end)
  end

  def ensure_response_to(msg) do
    # Not much to check here other than matching clauses.
    # AMQP lib handles most all of this.
    expect(Preloader, :preload_all, 1, fn -> :ok end)
    pid = generate_pid()
    send(pid, msg)
    Helpers.wait_for(pid)
  end

  test "basic_cancel", do: ensure_response_to({:basic_cancel, :anything})
  test "basic_cancel_ok", do: ensure_response_to({:basic_cancel_ok, :anything})
  test "basic_consume_ok", do: ensure_response_to({:basic_consume_ok, :anything})

  test "init / terminate - auto_sync enabled" do
    expect(Preloader, :preload_all, 1, fn -> :ok end)
    expect(FarmbotCore.BotState, :set_sync_status, 1, fn "synced" -> :ok end)

    expect(FarmbotCore.Leds, :green, 2, fn
      :solid ->
        :ok

      :really_fast_blink ->
        :ok
    end)

    pid = generate_pid()
    assert %{chan: nil, conn: nil, preloaded: true} == AutoSyncChannel.network_status(pid)
    GenServer.stop(pid, :normal)
  end

  test "handle_info(:preload, state) - preload error" do
    state = %{}
    reason = "Just a test"

    expect(Preloader, :preload_all, 1, fn ->
      {:error, reason}
    end)

    Helpers.expect_log("Error preloading. #{inspect(reason)}")
    assert {:noreply, state} == AutoSyncChannel.handle_info(:preload, state)
    assert_receive(:preload, 10)
  end

  test "handle_info({:basic_deliver, _, _}, %{preloaded: false} = state)" do
    state = %{preloaded: false}
    msg = {:basic_deliver, 0, 0}
    assert {:noreply, state} == AutoSyncChannel.handle_info(msg, state)
    assert_receive(:preload, 10)
  end

  # Blinked on 21 OCT 20. TODO: Rewrite
  test "delivery of auto sync messages" do
    expect(Preloader, :preload_all, 1, fn -> :ok end)

    expect(ConnectionWorker, :rpc_reply, 1, fn chan, device, label ->
      assert chan == %{fake_chan: true}
      assert device == "device_15"
      assert label == "thisismylabelinatestsuite"
      :ok
    end)

    key = "bot.device_15.sync.Device.46"

    {:ok, payload} =
      FarmbotCore.JSON.encode(%{
        "id" => 46,
        "args" => %{
          "label" => "thisismylabelinatestsuite"
        },
        "body" => %{name: "This is my bot"}
      })

    pid = generate_pid()
    # We need the process to be preloaded for these tests to work:
    %{preloaded: true} = AutoSyncChannel.network_status(pid)
    send(pid, {:basic_deliver, payload, %{routing_key: key}})

    expect(FarmbotExt.AMQP.AutoSyncAssetHandler, :handle_asset, fn kind, id, body ->
      assert kind == "Device"
      assert id == 46
      assert body == %{"name" => "This is my bot"}
      :ok
    end)

    Helpers.wait_for(pid)
    Process.sleep(1000)
  end

  test "disconnect" do
    state = %AutoSyncChannel{jwt: Helpers.fake_jwt_object()}

    expect(ConnectionWorker, :maybe_connect_autosync, 1, fn jwt_dot_bot ->
      assert jwt_dot_bot == state.jwt.bot
      :error123
    end)

    Helpers.expect_log("Failed to connect to AutoSync channel: :error123")
    AutoSyncChannel.handle_info(:connect, state)
  end
end

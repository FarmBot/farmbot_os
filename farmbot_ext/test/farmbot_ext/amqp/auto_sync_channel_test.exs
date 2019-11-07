defmodule AutoSyncChannelTest do
  alias FarmbotExt.AMQP.AutoSyncChannel

  use ExUnit.Case
  import Mox

  alias FarmbotCore.JSON
  alias FarmbotCore.Asset.{Query, Command, Sync}
  alias FarmbotExt.{JWT, API, AMQP.ConnectionWorker}

  @fake_jwt "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJhZ" <>
              "G1pbkBhZG1pbi5jb20iLCJpYXQiOjE1MDIxMjcxMTcsImp0a" <>
              "SI6IjlhZjY2NzJmLTY5NmEtNDhlMy04ODVkLWJiZjEyZDlhY" <>
              "ThjMiIsImlzcyI6Ii8vbG9jYWxob3N0OjMwMDAiLCJleHAiO" <>
              "jE1MDU1ODMxMTcsIm1xdHQiOiJsb2NhbGhvc3QiLCJvc191c" <>
              "GRhdGVfc2VydmVyIjoiaHR0cHM6Ly9hcGkuZ2l0aHViLmNvb" <>
              "S9yZXBvcy9mYXJtYm90L2Zhcm1ib3Rfb3MvcmVsZWFzZXMvb" <>
              "GF0ZXN0IiwiZndfdXBkYXRlX3NlcnZlciI6Imh0dHBzOi8vY" <>
              "XBpLmdpdGh1Yi5jb20vcmVwb3MvRmFybUJvdC9mYXJtYm90L" <>
              "WFyZHVpbm8tZmlybXdhcmUvcmVsZWFzZXMvbGF0ZXN0IiwiY" <>
              "m90IjoiZGV2aWNlXzE1In0.XidSeTKp01ngtkHzKD_zklMVr" <>
              "9ZUHX-U_VDlwCSmNA8ahOHxkwCtx8a3o_McBWvOYZN8RRzQV" <>
              "LlHJugHq1Vvw2KiUktK_1ABQ4-RuwxOyOBqqc11-6H_GbkM8" <>
              "dyzqRaWDnpTqHzkHGxanoWVTTgGx2i_MZLr8FPZ8prnRdwC1" <>
              "x9zZ6xY7BtMPtHW0ddvMtXU8ZVF4CWJwKSaM0Q2pTxI9GRqr" <>
              "p5Y8UjaKufif7bBPOUbkEHLNOiaux4MQr-OWAC8TrYMyFHzt" <>
              "eXTEVkqw7rved84ogw6EKBSFCVqwRA-NKWLpPMV_q7fRwiEG" <>
              "Wj7R-KZqRweALXuvCLF765E6-ENxA"

  setup :verify_on_exit!
  setup :set_mox_global

  def pretend_network_returned(fake_value) do
    jwt = JWT.decode!(@fake_jwt)

    test_pid = self()

    expect(Query, :auto_sync?, 2, fn -> false end)
    expect(Query, :first_sync?, 2, fn -> false end)

    expect(API, :get_changeset, fn _module ->
      send(test_pid, :preload_all_called)
      changeset = Sync.changeset(%Sync{}, %{})
      {:ok, changeset}
    end)

    expect(ConnectionWorker, :maybe_connect_autosync, fn jwt ->
      send(test_pid, {:maybe_connect_called, jwt})
      fake_value
    end)

    stub(ConnectionWorker, :close_channel, fn _ ->
      send(test_pid, :close_channel_called)
      :ok
    end)

    stub(ConnectionWorker, :rpc_reply, fn chan, jwt_dot_bot, label ->
      send(test_pid, {:rpc_reply_called, chan, jwt_dot_bot, label})
      :ok
    end)

    {:ok, pid} = AutoSyncChannel.start_link([jwt: jwt], [])
    assert_receive :preload_all_called
    assert_receive {:maybe_connect_called, "device_15"}

    Map.merge(%{pid: pid}, AutoSyncChannel.network_status(pid))
  end

  def under_normal_conditions() do
    fake_con = %{fake: :conn}
    fake_chan = %{fake: :chan}
    pretend_network_returned(%{conn: fake_con, chan: fake_chan})
  end

  test "network returns `nil`" do
    results = pretend_network_returned(nil)
    %{conn: has_conn, chan: has_chan, preloaded: is_preloaded} = results

    assert has_chan == nil
    assert has_conn == nil
    assert is_preloaded
  end

  test "network returns unexpected object (probably an error)" do
    results = pretend_network_returned({:something, :else})
    %{conn: has_conn, chan: has_chan, preloaded: is_preloaded} = results

    assert has_chan == nil
    assert has_conn == nil
    assert is_preloaded
  end

  test "expected object bootstraps process state" do
    fake_con = %{fake: :conn}
    fake_chan = %{fake: :chan}
    fake_response = %{conn: fake_con, chan: fake_chan}

    results = pretend_network_returned(fake_response)

    %{conn: real_conn, chan: real_chan, preloaded: is_preloaded, pid: pid} = results

    assert real_chan == fake_chan
    assert real_conn == fake_con
    assert is_preloaded
    send(pid, {:basic_cancel, "--NOT USED--"})
    assert_receive :close_channel_called, 150
  end

  test "catch-all clause for inbound AMQP messages" do
    fake_con = %{fake: :conn}
    fake_chan = %{fake: :chan}
    fake_response = %{conn: fake_con, chan: fake_chan}

    %{pid: pid} = pretend_network_returned(fake_response)

    payload =
      JSON.encode!(%{
        args: %{label: "xyz"}
      })

    send(pid, {:basic_deliver, payload, %{routing_key: "WRONG!"}})
    assert_receive {:rpc_reply_called, %{fake: :chan}, "device_15", "xyz"}
  end

  test "wont autosync unknown assets" do
    fake_con = %{fake: :conn}
    fake_chan = %{fake: :chan}
    fake_response = %{conn: fake_con, chan: fake_chan}

    %{pid: pid} = pretend_network_returned(fake_response)

    payload =
      JSON.encode!(%{
        args: %{label: "xyz"}
      })

    send(pid, {:basic_deliver, payload, %{routing_key: "bot.device_15.sync.SavedGarden.999"}})
    assert_receive {:rpc_reply_called, %{fake: :chan}, "device_15", "xyz"}
  end

  test "ignores asset deletion when auto_sync is off" do
    %{pid: pid} = under_normal_conditions()
    test_pid = self()
    payload = '{"args":{"label":"foo"}}'
    key = "bot.device_15.sync.Device.999"

    stub(Query, :auto_sync?, fn ->
      send(test_pid, :called_auto_sync?)
      false
    end)

    stub(Query, :first_sync?, fn -> false end)

    send(pid, {:basic_deliver, payload, %{routing_key: key}})
    assert_receive :called_auto_sync?
  end

  test "handles Device assets" do
    %{pid: pid} = under_normal_conditions()
    test_pid = self()
    payload = '{"args":{"label":"foo"},"body":{}}'
    key = "bot.device_15.sync.Device.999"
    stub(Query, :auto_sync?, fn -> true end)
    stub(Query, :first_sync?, fn -> false end)

    stub(Command, :update, fn x, y, z ->
      send(test_pid, {:update_called, x, y, z})
      :ok
    end)

    send(pid, {:basic_deliver, payload, %{routing_key: key}})
    assert_receive {:update_called, "Device", 999, %{}}
  end

  def simple_asset_test_singleton(module_name) do
    %{pid: pid} = under_normal_conditions()
    test_pid = self()
    payload = '{"args":{"label":"foo"},"body":{"foo": "bar"}}'
    key = "bot.device_15.sync.#{module_name}.999"

    stub(Query, :auto_sync?, fn -> true end)
    stub(Query, :first_sync?, fn -> false end)

    stub(Command, :update, fn x, y, z ->
      send(test_pid, {:update_called, x, y, z})
      :ok
    end)

    stub(Command, :update, fn x, y, z ->
      send(test_pid, {:update_called, x, y, z})
      :ok
    end)

    send(pid, {:basic_deliver, payload, %{routing_key: key}})

    assert_receive {:update_called, ^module_name, 999, %{"foo" => "bar"}}
  end

  test "handles auto_sync of 'no_cache' when auto_sync is false" do
    test_pid = self()
    %{pid: pid} = under_normal_conditions()

    key = "bot.device_15.sync.FbosConfig.999"
    payload = '{"args":{"label":"foo"},"body":{"foo": "bar"}}'

    stub(Query, :auto_sync?, fn ->
      send(test_pid, :called_auto_sync?)
      false
    end)

    stub(Query, :first_sync?, fn -> false end)

    stub(Command, :update, fn kind, id, params ->
      send(test_pid, {:update_called, kind, id, params})
      :ok
    end)

    send(pid, {:basic_deliver, payload, %{routing_key: key}})
    assert_receive :called_auto_sync?
    assert_receive {:update_called, "FbosConfig", 999, %{"foo" => "bar"}}
  end

  test "auto_sync disabled, resource not in @cache_kinds" do
    test_pid = self()
    %{pid: pid} = under_normal_conditions()

    key = "bot.device_15.sync.Point.999"
    payload = '{"args":{"label":"foo"},"body":{"foo": "bar"}}'

    stub(Query, :auto_sync?, fn ->
      send(test_pid, :called_auto_sync?)
      false
    end)

    stub(Query, :first_sync?, fn -> false end)

    stub(Command, :new_changeset, fn kind, id, params ->
      send(test_pid, {:new_changeset_called, kind, id, params})
      :ok
    end)

    send(pid, {:basic_deliver, payload, %{routing_key: key}})
    assert_receive {:new_changeset_called, "Point", 999, %{"foo" => "bar"}}
  end

  test "handles FbosConfig", do: simple_asset_test_singleton("FbosConfig")
  test "handles FirmwareConfig", do: simple_asset_test_singleton("FirmwareConfig")
  test "handles FarmwareEnv", do: simple_asset_test_plural("FarmwareEnv")
  test "handles FarmwareInstallation", do: simple_asset_test_plural("FarmwareInstallation")

  defp simple_asset_test_plural(module_name) do
    %{pid: pid} = under_normal_conditions()
    test_pid = self()
    payload = '{"args":{"label":"foo"},"body":{"foo": "bar"}}'
    key = "bot.device_15.sync.#{module_name}.999"

    stub(Query, :auto_sync?, fn -> true end)
    stub(Query, :first_sync?, fn -> false end)

    stub(Command, :update, fn x, y, z ->
      send(test_pid, {:update_called, x, y, z})
      :ok
    end)

    send(pid, {:basic_deliver, payload, %{routing_key: key}})

    assert_receive {:update_called, ^module_name, 999, %{"foo" => "bar"}}
  end
end

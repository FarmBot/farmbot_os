defmodule FarmbotExt.AMQP.AutoSyncChannelTest do
  use ExUnit.Case
  import Mox
  # import ExUnit.CaptureIO #TODO(Rick) See my note below
  alias FarmbotExt.JWT

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

    expect(MockPreloader, :preload_all, fn ->
      send(test_pid, :preload_all_called)
      :ok
    end)

    expect(MockConnectionWorker, :maybe_connect, fn jwt ->
      send(test_pid, {:maybe_connect_called, jwt})
      fake_value
    end)

    stub(MockConnectionWorker, :close_channel, fn _ ->
      send(test_pid, :close_channel_called)
      nil
    end)

    {:ok, pid} = FarmbotExt.AMQP.AutoSyncChannel.start_link(jwt: jwt)
    assert_receive :preload_all_called
    assert_receive {:maybe_connect_called, "device_15"}

    Map.merge(%{pid: pid}, FarmbotExt.AMQP.AutoSyncChannel.network_status(pid))
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

  # TODO(Rick) This test does not work. It would be nice if it did. Going to
  #            work on more impactful stuff for now.
  #
  # test "unexpected [error] causes logger to trigger" do
  #   expected = "Failed to connect to AutoSync channel: {:something, :else}"
  #   boom =
  #     capture_io(fn ->
  #       pretend_network_returned({:something, :else})
  #       Process.sleep(100)
  #     end)
  #   assert(boom == expected)
  # end

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
    assert_receive :close_channel_called
  end
end

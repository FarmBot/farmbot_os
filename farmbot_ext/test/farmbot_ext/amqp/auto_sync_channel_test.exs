defmodule FarmbotExt.AMQP.AutoSyncChannelTest do
  use ExUnit.Case
  import Mox
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

    {:ok, pid} = FarmbotExt.AMQP.AutoSyncChannel.start_link(jwt: jwt)
    assert_receive :preload_all_called
    assert_receive {:maybe_connect_called, "device_15"}

    FarmbotExt.AMQP.AutoSyncChannel.network_status(pid)
  end

  test "network returns `nil`" do
    %{conn: has_conn, chan: has_chan, preloaded: is_preloaded} = pretend_network_returned(nil)

    assert has_chan
    assert has_conn
    assert is_preloaded
  end

  test "network returns partial object"
  test "network returns expected object"
end

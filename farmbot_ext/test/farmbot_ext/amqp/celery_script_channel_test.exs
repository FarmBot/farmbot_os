defmodule FarmbotExt.AMQP.CeleryScriptChannelTest do
  use ExUnit.Case
  import Mox
  alias FarmbotExt.JWT
  alias FarmbotExt.AMQP.{ConnectionWorker, CeleryScriptChannel}

  @jwt JWT.decode!(
         "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJhZ" <>
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
       )

  setup :verify_on_exit!
  setup :set_mox_global

  def pretend_network_returned(fake_value) do
    test_pid = self()

    expect(ConnectionWorker, :maybe_connect_celeryscript, fn jwt_dot_bot ->
      send(test_pid, {:maybe_connect_celeryscript_called, jwt_dot_bot})
      fake_value
    end)

    stub(ConnectionWorker, :close_channel, fn _ ->
      send(test_pid, :close_channel_called)
      :ok
    end)

    {:ok, pid} = CeleryScriptChannel.start_link([jwt: @jwt], [])
    assert_receive {:maybe_connect_celeryscript_called, "device_15"}

    {:ok, pid}
  end

  test "Network connection returning `nil`" do
    {:ok, pid} = pretend_network_returned(%{conn: nil, chan: nil})
    state = :sys.get_state(pid)
    refute state.chan
    refute state.conn
  end

  test "Network connection returning non-`nil`" do
    {:ok, pid} = pretend_network_returned(%{conn: %{a: :b}, chan: %{c: :d}})

    state = :sys.get_state(pid)
    assert state.chan == %{c: :d}
    assert state.conn == %{a: :b}
  end
end

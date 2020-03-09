defmodule AutoSyncChannelTest do

  import ExUnit.CaptureIO

  alias FarmbotExt.AMQP.AutoSyncChannel

  use ExUnit.Case, async: true
  use Mimic

  alias FarmbotExt.{
    JWT,
    API.Preloader,
    AMQP.ConnectionWorker
  }
  setup :verify_on_exit!
  setup :set_mimic_global

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

  def generate_pid do
    jwt = JWT.decode!(@fake_jwt)
    ok = fn -> :ok end
    ok1 = fn _ -> :ok end
    # Test output will fill with huge termination errors
    # if this is not stubbed.
    stub(ConnectionWorker, :close_channel, ok1)

    # Happy Path: Pretend preloading went OK
    expect(Preloader, :preload_all, 1, ok)

    # Happy Path: Pretend autosync is enabled
    expect(FarmbotCore.Asset.Query, :auto_sync?, 1, fn -> true end)

    # Happy Path: Set status to "synced" and only that.
    expect(FarmbotCore.BotState, :set_sync_status, 1, fn "synced" -> :ok end)

    # It will try to connect to authsync channel after init.
    # we're not going to actually connect to a server in our
    # test suite except under limited circumstances.
    expect(ConnectionWorker, :maybe_connect_autosync, ok1)

    stub(FarmbotExt.API.EagerLoader.Supervisor, :drop_all_cache, ok)
    {:ok, pid} = AutoSyncChannel.start_link([jwt: jwt], [])
    pid
  end

  test "init / terminate" do
    pid = generate_pid()
    assert %{chan: nil, conn: nil, preloaded: true} == AutoSyncChannel.network_status(pid)
    Process.exit(pid, :normal)
  end
end

defmodule FarmbotFirmware.VCRTest do
  use ExUnit.Case
  alias FarmbotFirmware.StubTransport
  alias FarmbotFirmware.VCR

  test "saves a vcr when starting a server" do
    vcr_path = path()
    {:ok, server} = FarmbotFirmware.start_link([transport: StubTransport, vcr_path: vcr_path], [])
    :ok = FarmbotFirmware.exit_vcr_mode(server)
    assert File.exists?(vcr_path)
  end

  test "saves a vcr at runtime" do
    vcr_path = path()
    {:ok, server} = FarmbotFirmware.start_link([transport: StubTransport], [])
    refute File.exists?(vcr_path)
    :ok = FarmbotFirmware.enter_vcr_mode(server, vcr_path)
    :ok = FarmbotFirmware.exit_vcr_mode(server)
    assert File.exists?(vcr_path)
  end

  test "plays back a vcr" do
    vcr_path = path()
    {:ok, server} = FarmbotFirmware.start_link([transport: StubTransport, vcr_path: vcr_path], [])
    FarmbotFirmware.command(server, {:pin_write, [p: 13, v: 1]})
    FarmbotFirmware.request(server, {:pin_read, [p: 13]})
    :ok = FarmbotFirmware.exit_vcr_mode(server)
    VCR.playback!(vcr_path)
  end

  defp path do
    "/tmp/#{:os.system_time()}.vcr.txt"
  end
end

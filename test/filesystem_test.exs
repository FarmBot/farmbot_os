defmodule FarmbotOS.FilesystemTest do
  use ExUnit.Case
  use Mimic
  setup :verify_on_exit!
  alias FarmbotOS.FileSystem

  test "shutdown_reason_path/0" do
    expected = "/tmp/farmbot/last_shutdown_reason"
    actual = FileSystem.shutdown_reason_path()
    assert expected == actual
  end
end

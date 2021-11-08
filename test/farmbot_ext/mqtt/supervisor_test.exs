defmodule FarmbotOS.MQTT.SupervisorTest do
  require Helpers

  use ExUnit.Case
  use Mimic
  alias FarmbotOS.MQTT.Supervisor, as: S

  setup :verify_on_exit!
  setup :set_mimic_global

  test "process lifecycle" do
    Helpers.use_fake_jwt()
    {:ok, pid} = S.start_link([], [])
    _ = Process.unlink(pid)
    :ok = GenServer.stop(pid, :normal, 3_000)
  end
end

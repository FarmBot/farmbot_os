Application.ensure_all_started(:farmbot)
Application.ensure_all_started(:mimic)

tz = System.get_env("TZ") || Timex.local().time_zone

[
  Circuits.UART,
  FarmbotCore.Celery,
  FarmbotCore.Celery.Compiler.Lua,
  FarmbotCore.Celery.Scheduler,
  FarmbotCore.Celery.SpecialValue,
  FarmbotCore.Celery.SysCalls,
  FarmbotCore.Celery.SysCalls.Stubs,
  FarmbotCore.Asset,
  FarmbotCore.Asset.Private,
  FarmbotCore.Asset.Repo,
  FarmbotCore.BotState,
  FarmbotCore.Firmware.Avrdude,
  FarmbotCore.Firmware.ConfigUploader,
  FarmbotCore.Firmware.Flash,
  FarmbotCore.Firmware.FlashUtils,
  FarmbotCore.Firmware.Resetter,
  FarmbotCore.Firmware.TxBuffer,
  FarmbotCore.Firmware.UARTCore,
  FarmbotCore.Firmware.UARTCoreSupport,
  FarmbotCore.Firmware.UARTDetector,
  FarmbotCore.FirmwareEstopTimer,
  FarmbotCore.LogExecutor,
  MuonTrap,
  Timex
]
|> Enum.map(&Mimic.copy/1)

timeout = System.get_env("EXUNIT_TIMEOUT") || "5000"
System.put_env("LOG_SILENCE", "true")

ExUnit.configure(
  max_cases: 1,
  assert_receive_timeout: String.to_integer(timeout)
)

ExUnit.start()

# Use this to stub out calls to `state.reset.reset()` in firmware.
defmodule StubReset do
  def reset(), do: :ok
end

defmodule NoOp do
  use GenServer

  def new(opts \\ []) do
    {:ok, pid} = start_link(opts)
    pid
  end

  def stop(pid) do
    _ = Process.unlink(pid)
    :ok = GenServer.stop(pid, :normal, 3_000)
  end

  def last_message(pid) do
    :sys.get_state(pid)
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def init([]) do
    {:ok, :no_message_yet}
  end

  def handle_info(next_message, _last_message) do
    {:noreply, next_message}
  end
end

defmodule SimpleCounter do
  def new(starting_value \\ 0) do
    Agent.start_link(fn -> starting_value end)
  end

  def get_count(pid) do
    Agent.get(pid, fn count -> count end)
  end

  def incr(pid, by \\ 1) do
    Agent.update(pid, fn count -> count + by end)
    pid
  end

  # Increment the counter by one and get the current count.
  def bump(pid, by \\ 1) do
    pid |> incr(by) |> get_count()
  end
end

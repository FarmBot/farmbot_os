Application.ensure_all_started(:farmbot)
Application.ensure_all_started(:mimic)

[
  AMQP.Basic,
  AMQP.Channel,
  AMQP.Queue,
  FarmbotCeleryScript.SysCalls,
  FarmbotCeleryScript.SysCalls.Stubs,
  FarmbotCore.Asset.Command,
  FarmbotCore.Asset.Private,
  FarmbotCore.Asset.Repo,
  FarmbotCore.BotState,
  FarmbotCore.Config,
  FarmbotCore.Leds,
  FarmbotCore.LogExecutor,
  FarmbotExt.AMQP.AutoSyncAssetHandler,
  FarmbotExt.AMQP.ConnectionWorker,
  FarmbotExt.AMQP.Support,
  FarmbotExt.AMQP.TerminalChannelSupport,
  FarmbotExt.API,
  FarmbotExt.APIFetcher,
  FarmbotExt.API.EagerLoader,
  FarmbotExt.API.EagerLoader.Supervisor,
  FarmbotExt.API.Preloader,
  FarmbotExt.Bootstrap.Authorization
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

Application.ensure_all_started(:farmbot)
Application.ensure_all_started(:mimic)

[
  AMQP.Channel,
  FarmbotCeleryScript.SysCalls,
  FarmbotCeleryScript.SysCalls.Stubs,
  FarmbotCore.Asset.Command,
  FarmbotCore.Asset.Repo,
  FarmbotCore.Asset.Private,
  FarmbotCore.BotState,
  FarmbotCore.Leds,
  FarmbotCore.LogExecutor,
  FarmbotExt.AMQP.AutoSyncAssetHandler,
  FarmbotExt.AMQP.ConnectionWorker,
  FarmbotExt.API,
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

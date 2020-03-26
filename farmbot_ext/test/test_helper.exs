Application.ensure_all_started(:farmbot)

Mimic.copy(AMQP.Channel)
Mimic.copy(FarmbotCeleryScript.SysCalls.Stubs)
Mimic.copy(FarmbotCore.Asset.Command)
Mimic.copy(FarmbotCore.Asset.Query)
Mimic.copy(FarmbotCore.BotState)
Mimic.copy(FarmbotCore.Leds)
Mimic.copy(FarmbotCore.LogExecutor)
Mimic.copy(FarmbotExt.AMQP.ConnectionWorker)
Mimic.copy(FarmbotExt.API.EagerLoader.Supervisor)
Mimic.copy(FarmbotExt.API.Preloader)
Mimic.copy(FarmbotExt.API)
Mimic.copy(FarmbotExt.AMQP.AutoSyncAssetHandler)

timeout = System.get_env("EXUNIT_TIMEOUT")
System.put_env("LOG_SILENCE", "true")

if timeout do
  ExUnit.start(assert_receive_timeout: String.to_integer(timeout))
else
  ExUnit.start()
end

defmodule Helpers do
  defmacro expect_log(message) do
    quote do
      expect(FarmbotCore.LogExecutor, :execute, fn log ->
        assert log.message == unquote(message)
      end)
    end
  end
end

defmodule Helpers.NamedProcess do
  @moduledoc """
  NOTE: Inspired by ex_venture test suite. Thanks! -RC

  Register a globaly named process that fakes out a normally real process.

  Any messages this process receives will forward them to the test process via `send`.
  """

  use GenServer

  @doc """
  Link a new process to the test process

  This takes place outside of the supervision tree, so the process does
  not hang around.
  """
  def start_link(name) do
    GenServer.start_link(__MODULE__, [caller: self(), name: name], [name: {:global, name}])
  end

  @impl true
  def init(state) do
    {:ok, Enum.into(state, %{})}
  end

  @impl true
  def handle_cast(message, state) do
    send(state.caller, {state.name, {:cast, message}})
    {:noreply, state}
  end
end

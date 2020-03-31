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

timeout = System.get_env("EXUNIT_TIMEOUT") || "5000"
System.put_env("LOG_SILENCE", "true")

ExUnit.start(assert_receive_timeout: String.to_integer(timeout))

defmodule Helpers do
  # Maybe I don't need this?
  # Maybe I could use `start_supervised`?
  # https://hexdocs.pm/ex_unit/ExUnit.Callbacks.html#start_supervised/2

  @wait_time 13
  # Base case: We have a pid
  def wait_for(pid) when is_pid(pid), do: check_on_mbox(pid)
  # Failure case: We failed to find a pid for a module.
  def wait_for(nil), do: raise("Attempted to wait on bad module/pid")
  # Edge case: We have a module and need to try finding its pid.
  def wait_for(mod), do: wait_for(Process.whereis(mod))

  # Enter recursive loop
  defp check_on_mbox(pid) do
    Process.sleep(@wait_time)
    wait(pid, Process.info(pid, :message_queue_len))
  end

  # Exit recursive loop
  defp wait(_, {:message_queue_len, 0}), do: Process.sleep(@wait_time)
  # Continue recursive loop
  defp wait(pid, {:message_queue_len, _n}), do: check_on_mbox(pid)

  defmacro expect_log(message) do
    quote do
      expect(FarmbotCore.LogExecutor, :execute, fn log ->
        assert log.message == unquote(message)
      end)
    end
  end
end

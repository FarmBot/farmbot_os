defmodule Farmbot.Firmware.Supervisor.BlockUntilUp do
  @moduledoc """
  Quick and dirty task that waits for the :firmware_initialized or :firmware_idle
  global events.
  """

  @timeout_ms 60_000
  use Farmbot.Logger

  def start_link do
    block_until_up()
    :ignore
  end

  def block_until_up do
    Logger.debug 1, "Waiting for Firmware to be initialized."
    Farmbot.System.Registry.subscribe(self())
    Process.send_after(self(), :block_timeout, @timeout_ms)
    do_block()
  end

  defp do_block do
    receive do
      {Farmbot.System.Registry, {Farmbot.Firmware, :firmware_initialized}} ->
        Logger.debug 1, "Firmware initialized. Finishing init."
        :ok
      {Farmbot.System.Registry, {Farmbot.Firmware, :firmware_idle}} ->
        Logger.debug 1, "Firware is idle. Finishing init."
        :ok
      :block_timeout ->
        Logger.error 1, "Firmware wasn't initialized after 60 seconds. Ignoring."
        {:error, :block_timeout}
      _ -> do_block()
    after
      @timeout_ms ->
        Logger.error 1, "Didn't get any registry messages for #{@timeout_ms} ms."
        {:error, :timeout}
    end
  end
end

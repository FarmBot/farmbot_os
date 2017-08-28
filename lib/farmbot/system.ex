defmodule Farmbot.System do
  @moduledoc """
  Common functionality that should be implemented by a system
  """

  error_msg = """
  Please configure your `:system_tasks` behaviour!
  """

  @system_tasks Application.get_env(:farmbot, :behaviour)[:system_tasks] || Mix.raise error_msg

  @typedoc "Reason for a task to execute. Should be human readable."
  @type reason :: binary

  @typedoc "Any ole data that caused a factory reset. Will try to format it as a human readable binary."
  @type unparsed_reason :: term

  @doc """
  Should remove all persistant data. this includes:
  * network config
  * credentials
  * database
  """
  @callback factory_reset(reason) :: no_return

  @doc "Restarts the machine."
  @callback reboot(reason) :: no_return

  @doc "Shuts down the machine."
  @callback shutdown(reason) :: no_return

  #TODO(Connor) Format `unparsed_reason` into a human readable binary.

  use Farmbot.DebugLog

  @doc "Remove all configuration data, and reboot."
  @spec factory_reset(unparsed_reason) :: no_return
  def factory_reset(reason) do
    try do
      raise "Doing factory reset: #{inspect reason}", System.stacktrace()
    rescue
      _e ->
        # debug_log "Doing factory reset: #{inspect e}"
        # debug_log "#{inspect System.stacktrace()}"
        @system_tasks.factory_reset(reason)
    end
  end

  @doc "Reboot."
  @spec reboot(unparsed_reason) :: no_return
  def reboot(reason) do
    @system_tasks.reboot(reason)
  end

  @doc "Shutdown."
  @spec shutdown(unparsed_reason) :: no_return
  def shutdown(reason) do
    @system_tasks.shutdown(reason)
end end

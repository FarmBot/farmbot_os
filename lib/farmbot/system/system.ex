defmodule Farmbot.System do
  @moduledoc """
  Common functionality that should be implemented by a system
  """

  alias Farmbot.System.Init.Ecto

  error_msg = """
  Please configure `:system_tasks` and `:data_path`!
  """

  @system_tasks Application.get_env(:farmbot, :behaviour)[:system_tasks] || Mix.raise(error_msg)
  @data_path Application.get_env(:farmbot, :data_path) || Mix.raise(error_msg)

  @typedoc "Reason for a task to execute. Should be human readable."
  @type reason :: binary

  @typedoc "Any ole data that caused a factory reset. Will try to format it as a human readable binary."
  @type unparsed_reason :: any

  @doc """
  Should remove all persistant data. this includes:
  * network config
  * credentials
  """
  @callback factory_reset(reason) :: no_return

  @doc "Restarts the machine."
  @callback reboot(reason) :: no_return

  @doc "Shuts down the machine."
  @callback shutdown(reason) :: no_return

  @doc "Remove all configuration data, and reboot."
  @spec factory_reset(unparsed_reason) :: no_return
  def factory_reset(reason) do
    formatted = format_reason(reason)
    Ecto.drop()
    write_file(reason)
    @system_tasks.factory_reset(formatted)
  end

  @doc "Reboot."
  @spec reboot(unparsed_reason) :: no_return
  def reboot(reason) do
    formatted = format_reason(reason)
    write_file(reason)
    @system_tasks.reboot(formatted)
  end

  @doc "Shutdown."
  @spec shutdown(unparsed_reason) :: no_return
  def shutdown(reason) do
    formatted = format_reason(reason)
    write_file(reason)
    @system_tasks.shutdown(formatted)
  end

  defp write_file(reason) do
    file = Path.join(@data_path, "last_shutdown_reason")
    File.write!(file, reason)
  end

  @ref Mix.Project.config()[:commit]
  @target Mix.Project.config()[:target]
  @env Mix.env()

  @doc "Format an error for human consumption."
  def format_reason(reason) do
    raise "deleteme"
  rescue
    _ ->
      [_ | [_ | stack]] = System.stacktrace()
      stack = Enum.map(stack, fn er -> "\t#{inspect(er)}" end) |> Enum.join("\r\n")

      do_format_reason(reason) <> """

      environment: #{@env}
      source_ref:  #{@ref}
      target:      #{@target}
      Stacktrace:
        [
      #{stack}
        ]
      """
  end

  # This mess of pattern matches cleans up erlang startup errors. It's very
  # recursive, and kind of cryptic, but should always produce a human readable
  # message that can be read by an end user.

  defp do_format_reason({
         :error,
         {:shutdown, {:failed_to_start_child, Farmbot.Bootstrap.Supervisor, rest}}
       }) do
    do_format_reason(rest)
  end

  defp do_format_reason({:error, {:shutdown, {:failed_to_start_child, child, rest}}}) do
    {failed_child, failed_reason} = enumerate_ftsc_error(child, rest)

    """
    Failed to start child: #{failed_child}
    reason: #{do_format_reason(failed_reason)}

    This is likely a bug. Please copy or screenshot this error and send it to
    the Farmbot developers.
    """
  end

  defp do_format_reason({:bad_return, {Farmbot.Bootstrap.Supervisor, :init, error}}) do
    """
    Failed to Authorize with Farmbot Web Services.
    reason: #{do_format_reason(error)}

    This is likely because of bad configuration.
    """
  end

  defp do_format_reason({:error, reason}) when is_atom(reason) or is_binary(reason) do
    reason |> to_string()
  end

  defp do_format_reason({:error, reason}), do: inspect(reason)

  defp do_format_reason({:failed_connect, [{:to_address, {server, port}}, {_, _, reason}]}) do
    """
    Failed to connect to server: #{server}:#{port} reason: #{do_format_reason(reason)}
    This is likely the result of a misconfigured "server" field during configuration.
    """
  end

  defp do_format_reason(reason), do: do_format_reason({:error, reason})

  # This cleans up nested supervisors/workers.
  defp enumerate_ftsc_error(_child, {:shutdown, {:failed_to_start_child, child, rest}}) do
    enumerate_ftsc_error(child, rest)
  end

  defp enumerate_ftsc_error(child, err) do
    {child, err}
  end
end

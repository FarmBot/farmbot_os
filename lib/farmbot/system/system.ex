defmodule Farmbot.System do
  @moduledoc """
  Common functionality that should be implemented by a system
  """

  alias Farmbot.System.Init.Ecto

  error_msg = """
  Please configure `:system_tasks` and `:data_path`!
  """

  @system_tasks Application.get_env(:farmbot, :behaviour)[:system_tasks]
  @system_tasks || Mix.raise(error_msg)

  @data_path Application.get_env(:farmbot, :data_path)
  @data_path || Mix.raise(error_msg)

  @typedoc """
  Reason for a task to execute. Should be human readable.
  """
  @type reason :: binary

  @typedoc """
  Any ole data that caused a factory reset.
  Will try to format it as a human readable binary.
  """
  @type unparsed_reason :: any

  @doc "Called when the Application stops."
  @callback stop(String.t) :: any

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

  def stop(data) do
    @system_tasks.stop(data)
  end

  @doc "Remove all configuration data, and reboot."
  @spec factory_reset(unparsed_reason) :: no_return
  def factory_reset(reason) do
    alias Farmbot.System.ConfigStorage
    import ConfigStorage, only: [get_config_value: 3]
    if Process.whereis ConfigStorage do
      if get_config_value(:bool, "settings", "disable_factory_reset") do
        reboot(reason)
      else
        do_reset(reason)
      end
    else
      do_reset(reason)
    end
  end

  defp do_reset(reason) do
    formatted = format_reason(reason)
    case formatted do
      nil -> reboot("Escape factory reset: #{inspect reason}")
      {:ignore, reason} -> reboot(reason)
      _ ->
        path = Farmbot.Farmware.Installer.install_root_path()
        File.rm_rf(path)
        Ecto.drop()
        write_file(formatted)
        @system_tasks.factory_reset(formatted)
    end
  end

  @doc "Reboot."
  @spec reboot(unparsed_reason) :: no_return
  def reboot(reason) do
    formatted = format_reason(reason)
    write_file(formatted)
    @system_tasks.reboot(formatted)
  end

  @doc "Shutdown."
  @spec shutdown(unparsed_reason) :: no_return
  def shutdown(reason) do
    formatted = format_reason(reason)
    write_file(formatted)
    @system_tasks.shutdown(formatted)
  end

  defp write_file(nil) do
    file = Path.join(@data_path, "last_shutdown_reason")
    File.rm_rf(file)
  end

  defp write_file(reason) do
    file = Path.join(@data_path, "last_shutdown_reason")
    File.write!(file, reason)
  end

  @ref Farmbot.Project.commit()
  @target Farmbot.Project.target()
  @env Farmbot.Project.env()

  @doc "Format an error for human consumption."
  def format_reason(reason) do
    formated = do_format_reason(reason)
    footer = """
    <hr>
    <p>
    <p>
    <p> <strong> environment: </strong> #{@env}
    <p> <strong> source_ref: </strong>  #{@ref}
    <p> <strong> target: </strong>      #{@target}
    <p>
    <p>
    """

    case formated do
      nil -> nil
      {:ignore, reason}  -> {:ignore, reason}
      formatted when is_binary(formatted) ->
        if String.contains?(formatted, "DbConnection") do
          {:ignore, """
          https://github.com/scouten/sqlite_ecto2/issues/204
          """}
        else
          formated <> footer
        end
    end
  end

  # This mess of pattern matches cleans up erlang startup errors. It's very
  # recursive, and kind of cryptic, but should always produce a human readable
  # message that can be read by an end user.
  alias Farmbot.Bootstrap
  def do_format_reason(
    {:error,
      {:shutdown,
        {:failed_to_start_child, Bootstrap.Supervisor, rest}}})
  do
    do_format_reason(rest)
  end

  def do_format_reason(
    {:error,
      {:shutdown,
        {:failed_to_start_child, child, rest}}})
  do
    {failed_child, failed_reason} = enumerate_ftsc_error(child, rest)
    if failed_reason do
      """
      Failed to start child: #{failed_child}
      reason: #{do_format_reason(failed_reason)}

      This is likely a bug. Please copy or screenshot this error and send it to
      the Farmbot developers.
      """
    else
      nil
    end
  end

  def do_format_reason({:bad_return, {Bootstrap.Supervisor, :init, error}}) do
    """
    Failed to Authorize with Farmbot Web Services.
    reason: #{do_format_reason(error)}

    This is likely because of bad configuration.
    """
  end

  def do_format_reason({:error, reason})
    when is_atom(reason) or is_binary(reason)
  do
    reason |> to_string()
  end

  def do_format_reason({:error, reason}), do: inspect(reason)

  def do_format_reason(
    {:failed_connect,
      [{:to_address, {server, port}}, {_, _, reason}]})
  do
    """
    Failed to connect to server: #{server}:#{port}
      reason: #{do_format_reason(reason)}
    This is likely the result of a
    misconfigured "server" field during configuration.
    """
  end

  # TODO(Connor) Remove this some day.
  def do_format_reason({{:case_clause, {:raise, %Sqlite.DbConnection.Error{}}}, _}) do
    {:ignore, """
    https://github.com/scouten/sqlite_ecto2/issues/204
    """}
  end

  def do_format_reason({:EXIT, {{:case_clause, {:raise, %Sqlite.DbConnection.Error{}}}, _}}) do
    {:ignore, """
    https://github.com/scouten/sqlite_ecto2/issues/204
    """}
  end

  def do_format_reason({:badarg, [{:ets, :lookup_element, _, _} | _]}) do
    {:ignore, """
    Bad Ecto call. This usually is a result of an over the air update and can
    likely be ignored.
    """}
  end

  def do_format_reason({{exception, [{module, function, args, info} | _] = stacktrace}, {module_, function_, args_}})
  when is_atom(exception)
  and is_atom(module)
  and is_atom(function)
  and is_list(args)
  and is_list(info)
  and is_atom(module_)
  and is_atom(function_)
  and is_list(args_) do
    """
    Caught exception: #{exception}
    #{inspect format_stacktrace(stacktrace)}
    """
  end

  def do_format_reason(reason), do: do_format_reason({:error, reason})

  def format_stacktrace(stacktrace, acc \\ [])

  def format_stacktrace([{_module, _function, arity, _info} = entry | rest], acc) when is_integer(arity) do
    format_stacktrace(rest, [entry | acc])
  end

  def format_stacktrace([{module, function, args, info} | rest], acc) when is_list(args) do
    entry = {module, function, sanitize_args(args), info}
    format_stacktrace(rest, [entry | acc])
  end

  def format_stacktrace([], acc), do: Enum.reverse(acc)

  def sanitize_args(args, acc \\ [])

  def sanitize_args([arg | rest], acc) do
    sanitize_args(rest, [sanitize_arg(arg) | acc])
  end

  def sanitize_args([], acc), do: Enum.reverse(acc)

  # Rudementary check for a token.
  def sanitize_arg(arg) when byte_size(arg) > 80 do
    case Farmbot.Jwt.decode(arg) do
      {:ok, _} -> "[TOKEN REDACTED BY SANITIZER]"
      _ -> arg
    end
  end

  def sanitize_arg("device_" <> _) do
    "[DEVICE_ID REDACTED BY SANITIZER]"
  end

  def sanitize_arg(%{} = map_arg) do
    Map.new(map_arg, fn({key, val}) ->
      {key, sanitize_arg(val)}
    end)
  end

  def sanitize_arg(arg) when is_list(arg) do
    Enum.map(arg, fn(itm) ->
      sanitize_arg(itm)
    end)
  end

  def sanitize_arg(tuple) when is_tuple(tuple) do
    Tuple.to_list(tuple) |> sanitize_arg() |> List.to_tuple()
  end

  def sanitize_arg(arg), do: arg

  # This cleans up nested supervisors/workers.
  defp enumerate_ftsc_error(_child,
    {:shutdown,
      {:failed_to_start_child, child, rest}})
  do
    enumerate_ftsc_error(child, rest)
  end

  defp enumerate_ftsc_error(child, err) do
    {child, err}
  end

end

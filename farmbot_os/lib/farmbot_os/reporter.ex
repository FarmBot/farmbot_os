defmodule FarmbotOS.Reporter do
  @moduledoc """
  A `Rollbax.Reporter` that translates crashes and exits from processes to nicely-formatted
  Rollbar exceptions.
  """

  @behaviour Rollbax.Reporter

  def handle_event(:error, {_pid, format, data}) do
    handle_error_format(format, data)
  end

  def handle_event(_type, _event) do
    :next
  end

  # Ping timeouts are the result of a low quality connection.
  # We don't need to log them.
  defp handle_error_format(_, [
         {Tortoise.Registry, _},
         {:EXIT, _, :ping_timeout} | _
       ]) do
    :next
  end

  # Errors in a GenEvent handler.
  defp handle_error_format('** gen_event handler ' ++ _, [
         name,
         manager,
         last_message,
         state,
         reason
       ]) do
    {class, message, stacktrace} =
      format_as_exception(reason, "gen_event handler terminating")

    %Rollbax.Exception{
      class: class,
      message: message,
      stacktrace: stacktrace,
      custom: %{
        "name" => inspect(name),
        "manager" => inspect(manager),
        "last_message" => inspect(last_message),
        "state" => inspect(state)
      }
    }
  end

  # Errors in a task.
  defp handle_error_format('** Task ' ++ _, [
         name,
         starter,
         function,
         arguments,
         reason
       ]) do
    {class, message, stacktrace} =
      format_as_exception(reason, "Task terminating")

    %Rollbax.Exception{
      class: class,
      message: message,
      stacktrace: stacktrace,
      custom: %{
        "name" => inspect(name),
        "started_from" => inspect(starter),
        "function" => inspect(function),
        "arguments" => inspect(arguments)
      }
    }
  end

  defp handle_error_format('** State machine ' ++ _ = message, data) do
    if charlist_contains?(message, 'Callback mode') do
      :next
    else
      handle_gen_fsm_error(data)
    end
  end

  # Errors in a regular process.
  defp handle_error_format('Error in process ' ++ _, [pid, {reason, stacktrace}]) do
    exception = Exception.normalize(:error, reason)

    %Rollbax.Exception{
      class: "error in process (#{inspect(exception.__struct__)})",
      message: Exception.message(exception),
      stacktrace: stacktrace,
      custom: %{
        "pid" => inspect(pid)
      }
    }
  end

  # Any other error (for example, the ones logged through
  # :error_logger.error_msg/1). This reporter doesn't report those to Rollbar.
  defp handle_error_format(_format, _data) do
    :next
  end

  defp handle_gen_fsm_error([name, last_event, state, data, reason]) do
    {class, message, stacktrace} =
      format_as_exception(reason, "State machine terminating")

    %Rollbax.Exception{
      class: class,
      message: message,
      stacktrace: stacktrace,
      custom: %{
        "name" => inspect(name),
        "last_event" => inspect(last_event),
        "state" => inspect(state),
        "data" => inspect(data)
      }
    }
  end

  defp handle_gen_fsm_error(_data) do
    :next
  end

  defp format_as_exception(
         {maybe_exception, [_ | _] = maybe_stacktrace} = reason,
         class
       ) do
    # We do this &Exception.format_stacktrace_entry/1 dance just to ensure that
    # "maybe_stacktrace" is a valid stacktrace. If it's not,
    # Exception.format_stacktrace_entry/1 will raise an error and we'll treat it
    # as not a stacktrace.
    try do
      Enum.each(maybe_stacktrace, &Exception.format_stacktrace_entry/1)
    catch
      :error, _ ->
        format_stop_as_exception(reason, class)
    else
      :ok ->
        format_error_as_exception(maybe_exception, maybe_stacktrace, class)
    end
  end

  defp format_as_exception(reason, class) do
    format_stop_as_exception(reason, class)
  end

  defp format_stop_as_exception(reason, class) do
    {class <> " (stop)", Exception.format_exit(reason), _stacktrace = []}
  end

  defp format_error_as_exception(reason, stacktrace, class) do
    case Exception.normalize(:error, reason, stacktrace) do
      %ErlangError{} ->
        {class, Exception.format_exit(reason), stacktrace}

      exception ->
        class = class <> " (" <> inspect(exception.__struct__) <> ")"
        {class, Exception.message(exception), stacktrace}
    end
  end

  defp charlist_contains?(charlist, part) do
    :string.str(charlist, part) != 0
  end
end

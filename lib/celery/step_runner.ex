defmodule FarmbotOS.Celery.StepRunner do
  @moduledoc """
  Handles execution of compiled CeleryScript AST
  """
  alias FarmbotOS.Celery.{AST, Compiler}
  alias FarmbotOS.Celery.Compiler.Scope

  require Logger

  @doc """
  Steps through an entire AST.
  """
  def begin(listener, tag, %AST{} = ast) do
    time = FarmbotOS.Time.system_time_ms()
    state = %{listener: listener, tag: tag, start_time: time}

    do_step(state, Compiler.compile(ast, Scope.new()))
  end

  def do_step(state, [fun | rest]) when is_function(fun, 0) do
    case execute(state, fun) do
      # The step returned a list of compiled function.
      # We need to execute them next.
      # Use case: `_if` blocks, `execute` calls, etc..
      [_next_ast_or_fun | _] = more -> do_step(state, more ++ rest)
      # The step failed for a specific reason.
      {:error, _} = error -> not_ok(state, error)
      _ -> do_step(state, rest)
    end
  end

  def do_step(state, [{_, _, _} = elixir_ast | rest]) do
    {more, _env} = Macro.to_string(elixir_ast) |> Code.eval_string()
    do_step(state, [more] ++ rest)
  end

  def do_step(state, []) do
    send(state.listener, {:csvm_done, state.tag, :ok})
    :ok
  end

  def execute(state, fun) do
    try do
      lock_time = FarmbotOS.BotState.fetch().informational_settings.locked_at

      if state.start_time > lock_time do
        fun.()
      else
        err = {:error, "Canceled sequence due to emergency lock."}
        not_ok(state, err)
      end
    rescue
      e -> not_ok(state, e)
    catch
      _kind, e -> not_ok(state, e)
    end
  end

  defp not_ok(state, original_error) do
    msg = "CeleryScript Exception: #{inspect(original_error)}"
    Logger.warning(msg)

    error = format_error(original_error)
    send(state.listener, {:csvm_done, state.tag, error})
    error
  end

  defp format_error(%{message: e}), do: format_error(e)
  defp format_error(%{term: e}), do: format_error(e)
  defp format_error({:badmatch, error}), do: format_error(error)
  defp format_error({:error, {:error, e}}), do: format_error(e)

  defp format_error({:error, {:badmatch, error}}),
    do: format_error({:error, error})

  defp format_error({:error, e}) when is_binary(e), do: {:error, e}
  defp format_error({:error, e}), do: {:error, inspect(e)}
  defp format_error(err) when is_binary(err), do: {:error, err}
  defp format_error(err), do: {:error, inspect(err)}
end

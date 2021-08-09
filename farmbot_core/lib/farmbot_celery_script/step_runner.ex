defmodule FarmbotCeleryScript.StepRunner do
  @moduledoc """
  Handles execution of compiled CeleryScript AST
  """
  alias FarmbotCeleryScript.{AST, Compiler}
  alias FarmbotCeleryScript.Compiler.Scope

  require Logger
  @doc """
  Steps through an entire AST.
  """
  def begin(listener, tag, %AST{} = ast) do
    # Maybe I should wrap this in a function that declares
    # the `cs_scope` object?
    do_step(listener, tag, Compiler.compile(ast, Scope.new()))
  end

  def do_step(listener, tag, [fun | rest]) when is_function(fun, 0) do
    case execute(listener, tag, fun) do
      # The step returned a list of compiled function.
      # We need to execute them next.
      # Use case: `_if` blocks, `execute` calls, etc..
      [_next_ast_or_fun | _] = more -> do_step(listener, tag, more ++ rest)
      # The step failed for a specific reason.
      {:error, _} = error -> not_ok(listener, tag, error)
      _ -> do_step(listener, tag, rest)
    end
  end

  def do_step(listener, tag, [{_, _, _} = elixir_ast | rest]) do
    {more, _env} = Macro.to_string(elixir_ast) |> Code.eval_string()
    do_step(listener, tag, [more] ++ rest)
  end

  def do_step(listener, tag, []) do
    send(listener, {:csvm_done, tag, :ok})
    :ok
  end

  defp execute(listener, tag, fun) do
    try do
      fun.()
    rescue
      e -> not_ok(listener, tag, e, __STACKTRACE__)
    catch
      _kind, e -> not_ok(listener, tag, e, __STACKTRACE__)
    end
  end

  defp not_ok(listener, tag, original_error, trace \\ nil) do
    Logger.warn("CeleryScript Exception: #{inspect(original_error)} / #{inspect(trace)}")
    error = format_error(original_error)
    send(listener, {:csvm_done, tag, error})
    error
  end

  defp format_error(%{message: e}), do: format_error(e)
  defp format_error(%{term: e}), do: format_error(e)
  defp format_error({:badmatch, error}), do: format_error(error)
  defp format_error({:error, {:error, e}}), do: format_error(e)
  defp format_error({:error, {:badmatch, error}}), do: format_error({:error, error})
  defp format_error({:error, e}) when is_binary(e), do: {:error, e}
  defp format_error({:error, e}), do: {:error, inspect(e)}
  defp format_error(err) when is_binary(err), do: {:error, err}
  defp format_error(err), do: {:error, inspect(err)}
end

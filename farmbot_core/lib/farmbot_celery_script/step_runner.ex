defmodule FarmbotCeleryScript.StepRunner do
  @moduledoc """
  Handles execution of compiled CeleryScript AST
  """
  alias FarmbotCeleryScript.{AST, Compiler}
  alias FarmbotCeleryScript.Compiler.Scope

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
      [_next_ast_or_fun | _] = more ->
        do_step(listener, tag, more ++ rest)

      # The step failed for a specific reason.
      {:error, reason} ->
        message = if is_binary(reason) do reason else inspect(reason) end
        err = {:error, message}
        send(listener, {:csvm_done, tag, err})
        err
      _ ->
        do_step(listener, tag, rest)
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
      e ->
        IO.warn("CeleryScript Exception: ", __STACKTRACE__)
        result = {:error, Exception.message(e)}
        send(listener, {:csvm_done, tag, result})
        result
    catch
      _kind, error when is_binary(error) ->
        IO.warn("CeleryScript Error: #{error}", __STACKTRACE__)
        send(listener, {:csvm_done, tag, {:error, error}})
        {:error, error}

      _kind, error ->
        IO.warn("CeleryScript Error: #{inspect(error)}", __STACKTRACE__)
        send(listener, {:csvm_done, tag, {:error, inspect(error)}})
        {:error, inspect(error)}
    end
  end
end

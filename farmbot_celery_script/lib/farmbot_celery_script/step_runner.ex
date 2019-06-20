defmodule FarmbotCeleryScript.StepRunner do
  @moduledoc """
  Handles execution of compiled CeleryScript AST
  """
  alias FarmbotCeleryScript.{AST, Compiler}

  @doc """
  Steps through an entire AST.
  """
  def step(listener, tag, %AST{} = ast) do
    step(listener, tag, Compiler.compile(ast))
  end

  def step(listener, tag, [fun | rest]) when is_function(fun, 0) do
    case execute(listener, tag, fun) do
      [fun | _] = more when is_function(fun, 0) ->
        step(listener, tag, more ++ rest)

      {:error, reason} ->
        send(listener, {:step_complete, tag, {:error, reason}})
        {:error, reason}

      _ ->
        step(listener, tag, rest)
    end
  end

  def step(listener, tag, []) do
    send(listener, {:step_complete, tag, :ok})
    :ok
  end

  defp execute(listener, tag, fun) do
    try do
      fun.()
    rescue
      e ->
        IO.warn("CeleryScript Exception: ", __STACKTRACE__)
        result = {:error, Exception.message(e)}
        send(listener, {:step_complete, tag, result})
        result
    catch
      _kind, error ->
        IO.warn("CeleryScript Error: ", __STACKTRACE__)
        send(listener, {:step_complete, tag, {:error, error}})
        {:error, error}
    end
  end
end

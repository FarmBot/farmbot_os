defmodule Farmbot.CeleryScript do
  @moduledoc """
  CeleryScript is the scripting language that Farmbot OS understands.
  """

  alias Farmbot.CeleryScript.AST
  use Farmbot.Logger

  @doc "Execute an AST node."
  def execute(ast, env \\ struct(Macro.Env))

  def execute(%AST{kind: kind, body: body, args: args} = ast, env) do
    # Logger.busy 3, "doing: #{inspect ast}"
    maybe_log_comment(ast)
    case kind.execute(args, body, env) do
      {:ok, %Macro.Env{} = _env} = res -> res
      {:ok, %AST{}, %Macro.Env{} = env} -> {:ok, env}
      {:ok, %AST{} = ast} -> execute(ast, env)
      {:error, reason, env} ->
        # this stops messages from logging more than once in
        # sequences, rpc_request, etc.
        unless env.vars[:__errors__][env.module] do
          Logger.error 1, "CS Failed: [#{fe_kind(env.module)}] - #{inspect reason}"
        end
        new_env = %{env | vars: [{:__errors__, [{env.module, reason}| env.vars[:__errors__] || []]} | env.vars]}
        {:error, reason, new_env}
    end
  end

  defp maybe_log_comment(%AST{comment: nil}), do: :ok
  defp maybe_log_comment(%AST{comment: comment} = ast) do
    Logger.info 2, "[#{fe_kind(ast.kind)}] - #{comment}"
  end

  @doc "Get the more friendly name of this node."
  def fe_kind(kind) when is_atom(kind) do
    Module.split(kind) |> List.last() |> Macro.underscore()
  end

  def var(env, dirty_label, val) do
    case sanitize_var_name(dirty_label) do
      {:ok, label} ->
        new_vars = Keyword.put(env.vars, String.to_atom(label), val)
        new_env = %{env | vars: new_vars}
        {:ok, new_env}
      {:error, reason} ->
        {:error, reason, env}
    end
  end

  defp sanitize_var_name(name) do
    cond do
      String.contains?(name, " ") ->
        {:error, "variables may not contain special characters."}
      match?(<<"__", _ :: binary>>, name) ->
        {:error, "variables may not replace internal names."}
      match?(<<"pin", _ :: binary>>, name) ->
        {:error, "variables may not contain pattern: pin<number>."}
      name in ["x", "y", "z"] ->
        {:error, "variables may not be axis names."}
      true -> {:ok, name}
    end
  end

end

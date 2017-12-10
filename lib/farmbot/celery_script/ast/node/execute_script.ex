defmodule Farmbot.CeleryScript.AST.Node.ExecuteScript do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  allow_args [:label]

  def execute(%{label: label}, pairs, env) do
    env = mutate_env(env)
    case Farmbot.Farmware.lookup(label) do
      {:ok, fw} -> do_execute(fw, pairs, env)
      {:error, reason} -> {:error, reason, env}
    end
  end

  defp do_execute(%Farmbot.Farmware{} = fw, pairs, env) do
    case Farmbot.Farmware.execute(fw, to_fw_env(pairs)) do
      %Farmbot.Farmware.Runtime{exit_status: 0} -> {:ok, env}
      %Farmbot.Farmware.Runtime{} -> {:error, "Farmware failed", env}
    end
  end

  defp to_fw_env(pairs, acc \\ [])
  defp to_fw_env([], acc), do: acc
  defp to_fw_env([%{args: %{label: key, value: value}} | rest], acc) do
    to_fw_env(rest, [{key, value} | acc])
  end
end

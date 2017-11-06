defmodule Farmbot.CeleryScript.AST.Node.ExecuteScript do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  allow_args [:label]

  def execute(%{label: label}, _, env) do
    env = mutate_env(env)
    case Farmbot.Farmware.lookup(label) do
      {:ok, fw} -> do_execute(fw, env)
      {:error, reason} -> {:error, reason, env}
    end
  end

  defp do_execute(%Farmbot.Farmware{} = fw, env) do
    case Farmbot.Farmware.execute(fw) do
      %Farmbot.Farmware.Runtime{exit_status: 0} -> {:ok, env}
      %Farmbot.Farmware.Runtime{} -> {:error, "Farmware failed", env}
    end
  end
end

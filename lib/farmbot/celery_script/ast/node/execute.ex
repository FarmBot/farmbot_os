defmodule Farmbot.CeleryScript.AST.Node.Execute do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  alias Farmbot.Asset
  allow_args [:sequence_id]

  def execute(%{sequence_id: id}, _, env) do
    env = mutate_env(env)
    seq = Asset.get_sequence_by_id(id)
    case seq do
      nil -> {:error, "Could not find sequence by id: #{id}", env}
      seq ->
        case Farmbot.CeleryScript.AST.decode(seq) do
          {:ok, ast} ->
            # remove this some day.
            ast_with_label = %{ast | args: Map.put(ast.args, :label, seq.name)}
            Farmbot.CeleryScript.execute(ast_with_label, env)
          {:error, reason} -> {:error, reason, env}
        end
    end
  end
end

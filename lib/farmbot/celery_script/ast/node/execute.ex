defmodule Farmbot.CeleryScript.AST.Node.Execute do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  allow_args [:sequence_id]

  import Ecto.Query

  def execute(%{sequence_id: id}, _, env) do
    env = mutate_env(env)
    repo = Farmbot.Repo.current_repo()
    seq = repo.one(from s in Farmbot.Asset.Sequence, where: s.id == ^id)
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

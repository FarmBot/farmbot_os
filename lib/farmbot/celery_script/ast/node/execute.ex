defmodule Farmbot.CeleryScript.AST.Node.Execute do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  allow_args [:sequence_id]

  import Ecto.Query

  def execute(%{sequence_id: id}, _, env) do
    env = mutate_env(env)
    repo = Farmbot.Repo.current_repo()
    seq = repo.one(from s in Farmbot.Repo.Sequence, where: s.id == ^id)
    case seq do
      nil -> {:error, "Could not find sequence by id: #{id}", env}
      seq -> Farmbot.CeleryScript.AST.decode(seq) |> Farmbot.CeleryScript.execute(env)
    end
  end
end

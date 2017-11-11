defimpl Farmbot.FarmEvent.Execution, for: Farmbot.Repo.Sequence do

  def execute_event(sequence, _now) do
    with {:ok, ast} <- Farmbot.CeleryScript.AST.decode(sequence) do
      case Farmbot.CeleryScript.execute(ast) do
        {:ok, _} -> :ok
        {:error, reason, _} ->
          {:error, reason}
      end
    else
      {:error, reason} -> {:error, reason}
    end
  end

end

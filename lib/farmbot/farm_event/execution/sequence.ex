defimpl Farmbot.FarmEvent.Execution, for: Farmbot.Asset.Sequence do

  def execute_event(sequence, _now) do
    with {:ok, ast} <- Farmbot.CeleryScript.AST.decode(sequence) do
      ast_with_label = %{ast | args: Map.put(ast.args, :label, sequence.name)}
      case Farmbot.CeleryScript.execute(ast_with_label) do
        {:ok, _} -> :ok
        {:error, reason, _} -> {:error, reason}
      end
    else
      {:error, reason} -> {:error, reason}
    end
  end

end

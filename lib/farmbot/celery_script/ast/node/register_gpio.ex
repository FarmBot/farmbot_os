defmodule Farmbot.CeleryScript.AST.Node.RegisterGpio do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  allow_args [:sequence_id, :pin_number]
  use Farmbot.Logger
  alias Farmbot.Asset

  def execute(%{sequence_id: id, pin_number: pin_num}, _, env) do
    env = mutate_env(env)
    case Asset.get_sequence_by_id(id) do
      nil -> {:error, "Could not find sequence by id: #{id}", env}
      seq ->
        Logger.busy 1, "Registering gpio: #{pin_num} to sequence: #{seq.name}"
        case Farmbot.System.GPIO.register_pin(pin_num, id) do
          :ok -> {:ok, env}
          {:error, reason} -> {:error, reason, env}
        end
    end
  end
end

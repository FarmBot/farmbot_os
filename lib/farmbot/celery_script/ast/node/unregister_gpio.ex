defmodule Farmbot.CeleryScript.AST.Node.UnregisterGpio do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  allow_args [:pin_number]
  use Farmbot.Logger

  def execute(%{pin_number: pin_num}, _, env) do
    env = mutate_env(env)
    case Farmbot.System.GPIO.unregister_pin(pin_num)do
      :ok -> {:ok, env}
      {:error, reason} -> {:error, reason, env}
    end
  end
end

defmodule Farmbot.CeleryScript.AST.Node.SetServoAngle do
  @moduledoc false

  use Farmbot.CeleryScript.AST.Node
  allow_args [:pin_number, :pin_value]

  def execute(%{pin_number: pin_number, pin_value: value}, _body, env) do
    env = mutate_env(env)
    case Farmbot.Firmware.set_servo_angle(pin_number, value) do
      :ok -> {:ok, env}
      {:error, reason} -> {:error, reason, env}
    end
  end

end

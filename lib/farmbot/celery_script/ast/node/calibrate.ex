defmodule Farmbot.CeleryScript.AST.Node.Calibrate do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  allow_args [:axis]

  def execute(%{axis: :all}, body, env) do
    # start with Z first, just for good messure.
    Enum.reduce([:z, :y, :x], env, &execute(&1, body, &2))
  end

  def execute(%{axis: axis}, _body, env) when axis in [:x, :y, :z] do
    case Farmbot.Firmware.calibrate(axis) do
      :ok -> {:ok, env}
      {:error, reason} -> {:error, reason, env}
    end
  end
end

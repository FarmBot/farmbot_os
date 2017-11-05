defmodule Farmbot.CeleryScript.AST.Node.ConfigUpdate do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  allow_args [:package]

  def execute(%{package: :farmbot_os}, _body, env) do
    {:error, "#{__MODULE__} :farmbot_os stub", env}
  end

  def execute(%{package: :arduino_firmware}, _body, env) do
    {:error, "#{__MODULE__} :arduino_firmware stub", env}
  end

  def execute(%{package: {:farmware, fw}}, body, env) do
    case Farmbot.Farmware.lookup(fw) do
      {:ok, _fw} -> {:error, "Farmware config updates not working", env}
      {:error, reason} -> {:error, reason, env}
    end
  end
end

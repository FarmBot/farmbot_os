defmodule Farmbot.CeleryScript.Command.FindHome do
  @moduledoc """
    FindHome
  """

  alias Farmbot.CeleryScript.Command
  alias Farmbot.Serial.Handler, as: UartHan
  @behaviour Command

  @doc ~s"""
    FindHomes an axis
      args: %{axis: "x" | "y" | "z" | "all"},
      body: []
  """
  @type axis :: String.t # "x" | "y" | "z" | "all"
  @spec run(%{axis: axis}, [], Ast.context) :: Ast.context
  def run(%{axis: "all"}, [], context) do
    run(%{axis: "z"}, [], context) # <= FindHome z FIRST to prevent plant damage
    run(%{axis: "y"}, [], context)
    run(%{axis: "x"}, [], context)
    context
  end

  def run(%{axis: "x"}, [], %{serial: serial} = context) do
    UartHan.write serial, "F11"
    context
  end

  def run(%{axis: "y"}, [], %{serial: serial} = context) do
    UartHan.write serial, "F12"
    context
  end

  def run(%{axis: "z"}, [], %{serial: serial} = context) do
    UartHan.write serial, "F13"
    context
  end
end

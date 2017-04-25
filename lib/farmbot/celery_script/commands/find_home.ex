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
  @spec run(%{axis: axis}, []) :: no_return
  def run(%{axis: "all"}, []) do
    run(%{axis: "z"}, []) # <= FindHome z FIRST to prevent plant damage
    run(%{axis: "y"}, [])
    run(%{axis: "x"}, [])
  end

  def run(%{axis: "x"}, []), do: UartHan.write "F11"
  def run(%{axis: "y"}, []), do: UartHan.write "F12"
  def run(%{axis: "z"}, []), do: UartHan.write "F13"
end

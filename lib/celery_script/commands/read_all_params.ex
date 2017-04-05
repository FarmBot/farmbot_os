defmodule Farmbot.CeleryScript.Command.ReadAllParams do
  @moduledoc """
    ReadAllParams
  """

  alias Farmbot.CeleryScript.Command
  alias Farmbot.Serial.Handler, as: UartHan
  @behaviour Command

  @doc ~s"""
    Reads all mcu_params
      args: %{},
      body: []
  """
  @spec run(%{}, []) :: no_return
  def run(%{}, []), do: UartHan.write("F20")
end

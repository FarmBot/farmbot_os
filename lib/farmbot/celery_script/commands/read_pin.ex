defmodule Farmbot.CeleryScript.Command.ReadPin do
  @moduledoc """
    ReadPin
  """

  alias Farmbot.CeleryScript.Command
  alias Farmbot.Serial.Handler, as: UartHan

  @behaviour Command

  @doc ~s"""
    Reads an arduino pin
      args: %{
        label: String.t
        pin_number: integer,
        pin_mode: integer}
      body: []
  """
  @spec run(%{label: String.t,
    pin_number: integer,
    pin_mode: Command.pin_mode}, [])
  :: no_return
  def run(%{label: _, pin_number: pin, pin_mode: mode}, []) do
    Farmbot.BotState.set_pin_mode(pin, mode)
    "F42 P#{pin} M#{mode}" |> UartHan.write
  end
end

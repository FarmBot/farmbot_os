defmodule Farmbot.CeleryScript.Command.WritePin do
  @moduledoc """
    WritePin
  """

  alias Farmbot.CeleryScript.Command
  alias Farmbot.Serial.Handler, as: UartHan

  @behaviour Command

  @doc ~s"""
    writes an arduino pin
      args: %{
        pin_number: integer,
        pin_mode: integer,
        pin_value: integer
      },
      body: []
  """
  @spec run(%{pin_number: integer,
    pin_mode: Command.pin_mode,
    pin_value: integer}, [])
  :: no_return
  def run(%{pin_number: pin, pin_mode: mode, pin_value: val}, []) do
    # sets the pin mode in bot state.
    Farmbot.BotState.set_pin_mode(pin, mode)
    "F41 P#{pin} V#{val} M#{mode}" |> UartHan.write
    # HACK read the pin back to make sure it worked
    Command.read_pin(%{pin_number: pin, pin_mode: mode, label: "ack"}, [])
    # HACK the above hack doesnt work some times so we just force it to work.
    Farmbot.BotState.set_pin_value(pin, val)
  end
end

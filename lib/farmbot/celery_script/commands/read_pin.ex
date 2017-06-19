defmodule Farmbot.CeleryScript.Command.ReadPin do
  @moduledoc """
    ReadPin
  """

  alias      Farmbot.CeleryScript.{Command, Types}
  alias      Farmbot.Serial.Handler, as: UartHan
  alias      Farmbot.Context
  @behaviour Command

  @doc ~s"""
    Reads an arduino pin
      args: %{
        label: binary
        pin_number: integer,
        pin_mode: integer}
      body: []
  """
  @type args :: %{
    label: binary,
    pin_number: Types.pin_number,
    pin_mode: Types.pin_mode
  }

  @spec run(args, [], Context.t) :: Context.t
  def run(%{label: _, pin_number: pin, pin_mode: mode}, [], context) do
    Farmbot.BotState.set_pin_mode(context, pin, mode)
    UartHan.write(context, "F42 P#{pin} M#{mode}")
    context
  end
end

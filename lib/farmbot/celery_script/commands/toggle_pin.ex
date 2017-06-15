defmodule Farmbot.CeleryScript.Command.TogglePin do
  @moduledoc """
    TogglePin
  """

  alias      Farmbot.CeleryScript.{Command, Types}
  alias      Farmbot.Context
  import     Command, [only: [write_pin: 3]]
  @behaviour Command

  @digital 0
  # @pwm 1

  @doc ~s"""
    toggles a digital pin
      args: %{pin_number: Types.pin_number},
      body: []
  """
  @spec run(%{pin_number: Types.pin_number}, [], Context.t) :: Context.t
  def run(%{pin_number: pin}, [], context) do
    # if we are trying to toggle an analog pin, make it digital i guess?
    # if it was analog, it will result in becoming 0
    Farmbot.BotState.set_pin_mode(context, pin, @digital)
    %{mode: @digital, value: val} = Farmbot.BotState.get_pin(context, pin)
    do_toggle(pin, val, context)
    context
  end

  @spec do_toggle(Types.pin_number, integer, Context.t) :: Context.t
  defp do_toggle(pin, val, context) do
    args = %{pin_number: pin, pin_mode: @digital, pin_value: nil}
    case val do
      # if it was off turn it on
      0 -> write_pin(%{args | pin_value: 1}, [], context)
      # if it was on (or analog) turn it off. (for safetey)
      _ -> write_pin(%{args | pin_value: 0}, [], context)
    end
  end
end

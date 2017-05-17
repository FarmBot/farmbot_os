defmodule Farmbot.CeleryScript.Command.TogglePin do
  @moduledoc """
    TogglePin
  """

  alias Farmbot.CeleryScript.{Command, Ast}
  @behaviour Command
  @digital 0
  # @pwm 1
  import Command, [only: [write_pin: 3]]

  @doc ~s"""
    toggles a digital pin
      args: %{pin_number: String.t},
      body: []
  """
  @spec run(%{pin_number: String.t}, [], Ast.context) :: Ast.context
  def run(%{pin_number: pin}, [], context) do
    # if we are trying to toggle an analog pin, make it digital i guess?
    # if it was analog, it will result in becoming 0
    Farmbot.BotState.set_pin_mode(pin, @digital)
    %{mode: @digital, value: val} = Farmbot.BotState.get_pin(pin)
    do_toggle(pin, val, context)
    context
  end

  @spec do_toggle(String.t, integer, Ast.context) :: Ast.context
  defp do_toggle(pin, val, context) do
    case val do
      # if it was off turn it on
      0 ->
        args = %{pin_number: pin, pin_mode: @digital, pin_value: 1}
        write_pin(args, [], context)
      # if it was on (or analog) turn it off. (for safetey)
      _ ->
        args = %{pin_number: pin, pin_mode: @digital, pin_value: 1}
        write_pin(args, [], context)
    end
  end
end

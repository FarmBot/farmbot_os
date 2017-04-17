defmodule Farmbot.CeleryScript.Command.TogglePin do
  @moduledoc """
    TogglePin
  """

  alias Farmbot.CeleryScript.Command
  @behaviour Command
  @digital 0
  @pwm 1
  import Command, [only: [write_pin: 2]]

  @doc ~s"""
    toggles a digital pin
      args: %{pin_number: String.t},
      body: []
  """
  @spec run(%{pin_number: String.t}, []) :: no_return
  def run(%{pin_number: pin}, []) do
    # if we are trying to toggle an analog pin, make it digital i guess?
    # if it was analog, it will result in becoming 0
    Farmbot.BotState.set_pin_mode(pin, @digital)
    %{mode: @digital, value: val} = Farmbot.BotState.get_pin(pin)
    do_toggle(pin, val)
  end

  @spec do_toggle(String.t, integer) :: no_return
  defp do_toggle(pin, val) do
    case val do
      # if it was off turn it on
      0 -> write_pin(%{pin_number: pin, pin_mode: @digital, pin_value: 1}, [])
      # if it was on (or analog) turn it off. (for safetey)
      _ -> write_pin(%{pin_number: pin, pin_mode: @digital, pin_value: 0}, [])
    end
  end
end

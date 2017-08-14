defmodule Farmbot.BotState.Pin do
  @moduledoc "State of a pin."
  
  @typedoc false
  @type digital :: 1
  @digital 1

  @typedoc false
  @type pwm :: 0
  @pwm 0
  
  @enforce_keys [:mode, :value]
  defstruct [:mode, :value]

  @typedoc "Pin."
  @type t :: %__MODULE__{mode: digital | pwm, value: number}

  @doc "Digital pin mode."
  def digital, do: @digital

  @doc "Pwm pin mode."
  def pwm, do: @pwm
end

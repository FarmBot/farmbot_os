defmodule Farmbot.Firmware.Utils do
  @moduledoc """
  Helpful utilities for working with Firmware data.
  """

  @compile {:inline, [num_to_bool: 1]}
  @doc "changes a number to a boolean. 1 => true, 0 => false"
  def num_to_bool(num) when num == 1, do: true
  def num_to_bool(num) when num == 0, do: false

  @compile {:inline, [fmnt_float: 1]}
  @doc "Format a float to a binary with two leading decimals."
  def fmnt_float(num) when is_float(num),
    do: :erlang.float_to_binary(num, [:compact, {:decimals, 2}])

  def fmnt_float(num) when is_integer(num), do: fmnt_float(num / 1)

  @compile {:inline, [extract_pin_mode: 1]}
  @doc "Changes `:digital` => 0, and `:analog` => 1"
  def extract_pin_mode(:digital), do: 0
  def extract_pin_mode(:analog), do: 1

  @doc "replace the firmware handler at runtime."
  def replace_firmware_handler(handler) do
    old = Application.get_all_env(:farmbot)[:behaviour]
    new = Keyword.put(old, :firmware_handler, handler)
    Application.put_env(:farmbot, :behaviour, new)
  end
end

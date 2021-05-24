defmodule FarmbotCore.Firmware.FloatingPoint do
  # alias FarmbotCore.JSON

  def encode(number) when is_integer(number) do
    encode(number / 1)
  end

  def encode(number) when is_float(number) do
    string =
      number
      |> Float.round(2)
      |> :erlang.float_to_binary(decimals: 2)

    string
  end

  def decode(string) do
    {num, _} = Float.parse(string)
    num
  end
end

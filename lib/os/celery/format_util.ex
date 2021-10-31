defmodule FarmbotOS.Celery.FormatUtil do
  def format_float(nil), do: nil

  def format_float(value) when is_integer(value) do
    format_float(value / 1)
  end

  def format_float(value) when is_float(value) do
    case :math.fmod(value, 1) do
      # value has no remainder
      rem when rem <= 0.0 -> :erlang.float_to_binary(value, decimals: 0)
      _ -> :erlang.float_to_binary(value, decimals: 1)
    end
  end
end

defmodule Farmbot.OS.IOLayer.FindHome do
  require Farmbot.Logger
  import Farmbot.Config, only: [get_config_value: 3]

  def execute(%{axis: "all"}, _) do
    do_reduce(["z", "y", "x"])
  end

  def execute(%{axis: axis}, _) do
    ep = get_config_value(:float, "hardware_params", "movement_enable_endpoints_#{axis}")
    ec = get_config_value(:float, "hardware_params", "encoder_enabled_#{axis}")
    do_find_home(ep, ec, axis)
  end

  defp do_reduce([axis | rest]) do
    case execute(%{axis: axis}, []) do
      :ok -> do_reduce(rest)
      {:error, reason} -> {:error, reason}
    end
  end

  defp do_reduce([]), do: :ok

  defp do_find_home(ep, ec, axis)

  defp do_find_home(ep, ec, axis) when ((ep == 0) or (ep == nil)) and ((ec == 0) or (ec == nil)) do
    {:error, "Could not find home on #{axis} axis because endpoints and encoders are disabled."}
  end

  defp do_find_home(ep, ec, axis) when ep == 1 or ec == 1 do
    Farmbot.Logger.busy 2, "Finding home on #{axis} axis."
    case Farmbot.Firmware.find_home(axis) do
      :ok -> :ok
      {:error, reason} when is_binary(reason) -> {:error, reason}
    end
  end

  defp do_find_home(ep, ec, _axis) do
    {:error, "Unknown  state of endpoints: #{ep} or encoders: #{ec}"}
  end
end

defmodule Farmbot.OS.IOLayer.FindHome do
  @moduledoc false

  alias Farmbot.Firmware

  def execute(%{axis: "all"} = args, body) do
    with :ok <- execute(%{args | axis: "z"}, body),
         :ok <- execute(%{args | axis: "y"}, body),
         :ok <- execute(%{args | axis: "x"}, body) do
      :ok
    end
  end

  def execute(%{axis: axis}, _body) do
    ep_param = :"movement_enable_endpoints_#{axis}"
    enc_param = :"encoder_enabled_#{axis}"

    # I'm sorry about these long lines
    with {:ok, {_, {:report_paramater_value, [{^ep_param, ep_val}]}}} <-
           Firmware.request({:paramater_read, [ep_param]}),
         {:ok, {_, {:report_paramater_value, [{^enc_param, enc_val}]}}} <-
           Firmware.request({:paramater_read, [enc_param]}) do
      command([String.to_existing_atom(axis)], ep_val, enc_val)
    else
      _ -> {:error, "Firmware Error"}
    end
  end

  defp command([axis], 0.0, 0.0) do
    {:error, "Could not find home on #{axis} axis because endpoints and encoders are disabled."}
  end

  defp command(args, _, _) do
    case Firmware.command({:command_movement_find_home, args}) do
      :ok -> :ok
      _ -> {:error, "Firmware Error"}
    end
  end
end

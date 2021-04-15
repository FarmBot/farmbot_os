defmodule FarmbotCore.Firmware.ConfigUploader do
  alias FarmbotCore.Asset
  alias FarmbotFirmware.Parameter

  def upload(state) do
    %{} = do_upload(state, maybe_get_config())
  end

  def maybe_get_config() do
    data = fetch_data()

    missing_key? =
      data
      |> Map.to_list()
      |> Enum.find(fn
        {key, nil} -> key
        {_, _} -> false
      end)

    if missing_key? do
      IO.puts("Missing key: #{inspect(missing_key?)}")
      nil
    else
      data
    end
  end

  defp do_upload(state, nil), do: state

  defp do_upload(state, _config_data) do
    Enum.map(Parameter.names(), fn name ->
      IO.puts("Still need to upload #{inspect(name)}")
    end)

    state
  end

  defp fetch_data() do
    %{} |> Map.merge(fbos_config()) |> Map.merge(fw_config())
  end

  defp fbos_config do
    keys = [:firmware_hardware, :firmware_path]
    Map.take(Asset.fbos_config(), keys)
  end

  defp fw_config do
    Map.take(Asset.firmware_config(), Parameter.names())
  end
end

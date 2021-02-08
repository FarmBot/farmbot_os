defmodule FarmbotOS.Lua.Ext.DataManipulation do
  @moduledoc """
  Extensions for manipulating data from Lua
  """

  alias FarmbotCore.{Asset, JSON}
  alias FarmbotCore.Asset.{Device, FbosConfig, FirmwareConfig}
  alias FarmbotOS.Lua.Util
  alias FarmbotOS.SysCalls.ResourceUpdate

  # def json_encode([data], lua) do
  #   IO.inspect(data, label: "==== ENCODE BEFORE")

  #   data
  #   |> Enum.into(%{})
  #   |> IO.inspect(label: "==== ENCODE AFTER")
  #   {["ENCODE"], lua}
  # end

  def json_decode([data], lua) do
    with {:ok, map} <- JSON.decode(data) do
      {[Util.map_to_table(map)], lua}
    else
      _ -> {[nil, "Error parsing JSON."], lua}
    end
  end

  def take_photo(_, lua) do
    case FarmbotOS.SysCalls.Farmware.execute_script("take-photo", %{}) do
      {:error, reason} -> {[reason], lua}
      _ -> {[], lua}
    end
  end

  def update_device([table], lua) do
    params = Map.new(table)
    _ = ResourceUpdate.update_resource("Device", nil, params)
    {[true], lua}
  end

  def get_device([field], lua) do
    device = Asset.device() |> Device.render()
    {[device[String.to_atom(field)]], lua}
  end

  def get_device(_, lua) do
    device = Asset.device() |> Device.render()
    {[Util.map_to_table(device)], lua}
  end

  def update_fbos_config([table], lua) do
    Map.new(table)
    |> Asset.update_fbos_config!()
    |> Asset.Private.mark_dirty!(%{})

    {[true], lua}
  end

  def get_fbos_config([field], lua) do
    fbos_config = Asset.fbos_config() |> FbosConfig.render()
    {[fbos_config[String.to_atom(field)]], lua}
  end

  def get_fbos_config(_, lua) do
    conf =
      Asset.fbos_config()
      |> FbosConfig.render()
      |> Util.map_to_table()

    {[conf], lua}
  end

  def update_firmware_config([table], lua) do
    Map.new(table)
    |> Asset.update_firmware_config!()
    |> Asset.Private.mark_dirty!(%{})

    {[true], lua}
  end

  def get_firmware_config([field], lua) do
    firmware_config = Asset.firmware_config() |> FirmwareConfig.render()
    {[firmware_config[String.to_atom(field)]], lua}
  end

  def get_firmware_config(_, lua) do
    firmware_config = Asset.firmware_config() |> FirmwareConfig.render()
    {[Util.map_to_table(firmware_config)], lua}
  end

  def new_farmware_env([table], lua) do
    params = Map.new(table)
    _ = Asset.new_farmware_env(params)
    {[true], lua}
  end

  def new_sensor_reading([table], lua) do
    params = Map.new(table)
    _ = Asset.new_sensor_reading!(params)
    {[true], lua}
  end
end

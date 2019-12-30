defmodule FarmbotOS.Lua.Ext.DataManipulation do
  @moduledoc """
  Extensions for manipulating data from Lua
  """

  import FarmbotOS.Lua.Util

  alias FarmbotCore.{
    Asset,
    Asset.Device,
    Asset.FbosConfig,
    Asset.FirmwareConfig
  }

  def update_device([table], lua) do
    params = Map.new(table)
    _ = Asset.update_device!(params)
    {[true], lua}
  end

  def get_device([field], lua) do
    device = Asset.device() |> Device.render()
    {[device[String.to_atom(field)]], lua}
  end

  def get_device(_, lua) do
    device = Asset.device() |> Device.render()
    {[map_to_table(device)], lua}
  end

  def update_fbos_config([table], lua) do
    params = Map.new(table)
    _ = Asset.update_fbos_config!(params)
    {[true], lua}
  end

  def get_fbos_config([field], lua) do
    fbos_config = Asset.fbos_config() |> FbosConfig.render()
    {[fbos_config[String.to_atom(field)]], lua}
  end

  def get_fbos_config(_, lua) do
    fbos_config = Asset.fbos_config() |> FbosConfig.render()
    {[map_to_table(fbos_config)], lua}
  end

  def update_firmware_config([table], lua) do
    params = Map.new(table)
    _ = Asset.update_firmware_config!(params)
    {[true], lua}
  end

  def get_firmware_config([field], lua) do
    firmware_config = Asset.firmware_config() |> FirmwareConfig.render()
    {[firmware_config[String.to_atom(field)]], lua}
  end

  def get_firmware_config(_, lua) do
    firmware_config = Asset.firmware_config() |> FirmwareConfig.render()
    {[map_to_table(firmware_config)], lua}
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

defmodule Farmbot.CeleryScript.Command.FindHome do
  @moduledoc """
    FindHome
  """

  alias Farmbot.CeleryScript.{Command, Types, Error}
  alias Farmbot.Serial.Handler, as: UartHan
  @behaviour Command

  @doc ~s"""
    FindHomes an axis
      args: %{axis: "x" | "y" | "z" | "all"},
      body: []
  """
  @spec run(%{axis: Types.axis}, [], Context.t) :: Context.t
  def run(%{axis: "all"}, [], context) do
    run(%{axis: "z"}, [], context) # <= FindHome z FIRST to prevent plant damage
    run(%{axis: "y"}, [], context)
    run(%{axis: "x"}, [], context)
    context
  end

  def run(%{axis: "x"}, [], context) do
    ep_x = Farmbot.BotState.get_param(context, "movement_enable_endpoints_x")
    ec_x = Farmbot.BotState.get_param(context, "encoder_enabled_x")
    if {ep_x, ec_x} == {0, 0} do
      raise Error, "Could not find home because endpoints and encoders are disabled on X axis."
    end

    UartHan.write context, "F11"
    context
  end

  def run(%{axis: "y"}, [], context) do
    ep_y = Farmbot.BotState.get_param(context, "movement_enable_endpoints_y")
    ec_y = Farmbot.BotState.get_param(context, "encoder_enabled_y")
    if {ep_y, ec_y} == {0, 0} do
      raise Error, "Could not find home because endpoints and encoders are disabled on Y axis."
    end

    UartHan.write context, "F12"
    context
  end

  def run(%{axis: "z"}, [], context) do
    ep_z = Farmbot.BotState.get_param(context, "movement_enable_endpoints_z")
    ec_z = Farmbot.BotState.get_param(context, "encoder_enabled_z")
    if {ep_z, ec_z} == {0, 0} do
      raise Error, "Could not find home because endpoints and encoders are disabled on Z axis."
    end

    UartHan.write context, "F13"
    context
  end
end

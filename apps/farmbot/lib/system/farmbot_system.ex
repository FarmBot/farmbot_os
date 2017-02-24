defmodule Farmbot.System do
  @moduledoc """
    Common functionality that should be implemented by a system
  """
  @target Mix.Project.config()[:target]

  @doc """
    Reboots your bot.
  """
  def reboot(), do: mod(@target).reboot

  @doc """
    Powers off your bot.
  """
  def power_off(), do: mod(@target).power_off

  @doc """
    Factory resets your bot.
  """
  def factory_reset(), do: mod(@target).factory_reset

  @spec mod(atom) :: atom
  defp mod(target), do: Module.concat([Farmbot, System, target])

  # Behavior
  @callback reboot() :: no_return
  @callback power_off() :: no_return
  @callback factory_reset() :: no_return
end

defmodule Farmbot.System do
  @moduledoc """
    Common functionality that should be implemented by a system
  """
  @target Mix.Project.config()[:target]

  @doc """
    Reboots your bot.
  """
  def reboot() do
    mod(@target).reboot
  end

  @doc """
    Powers off your bot.
  """
  def power_off() do
    mod(@target).power_off
  end

  @spec mod(atom) :: atom
  defp mod(target), do: Module.concat([Farmbot, System, target])
end

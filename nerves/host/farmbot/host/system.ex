defmodule Farmbot.Host.System do
  @moduledoc "Host implementation for Farmbot.System."

  @behaviour Farmbot.System

  def factory_reset(reason) do
    shutdown(reason)
  end

  def reboot(reason), do: shutdown(reason)

  def shutdown(_reason), do: :init.stop()
end

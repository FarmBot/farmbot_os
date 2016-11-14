defmodule Farmbot.Logger do
  @moduledoc """
    Right now this doesn't do anything but eventually it will save log messages
    and push them to teh frontend
  """
  def log(message, channels, tags) do
    RPC.MessageHandler.log(message, channels, tags)
  end
end

defmodule Farmbot.Sync.EventManager do
  @moduledoc """
    Delegeates diff events
  """

  def start_link, do: GenEvent.start_link(name: __MODULE__)
  def call(handler, thing), do: GenEvent.call(__MODULE__, handler, thing)
end

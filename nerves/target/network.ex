defmodule Farmbot.Target.Network do
  @moduledoc "Bring up network."

  @behaviour Farmbot.System.Init

  def start_link(_, _opts) do
    require IEx; IEx.pry
    :ignore
  end
end

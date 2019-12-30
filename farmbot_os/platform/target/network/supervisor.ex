defmodule FarmbotOS.Platform.Target.Network.Supervisor do
  @moduledoc """
  Supervises the NetworkManager
  """

  use Supervisor
  alias FarmbotOS.Platform.Target.Network

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init([]) do
    children = [
      Network
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end

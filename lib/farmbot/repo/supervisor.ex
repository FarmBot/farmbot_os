defmodule Farmbot.Repo.Supervisor do
  @moduledoc "Hey!"

  @repos [Farmbot.Repo.A, Farmbot.Repo.B]

  use Supervisor

  def start_link(token, opts \\ []) do
    Supervisor.start_link(__MODULE__, token, opts)
  end

  def init(_token) do
    @repos
    |> Enum.map(fn repo ->
         supervisor(repo, [])
       end)
    |> Kernel.++([worker(Farmbot.Repo, [@repos, [name: Farmbot.Repo]])])
    |> supervise(strategy: :one_for_one)
  end
end

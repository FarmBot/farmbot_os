defmodule Farmbot.Repo.Supervisor do
  @moduledoc false

  @repos [Farmbot.Repo.A, Farmbot.Repo.B]

  use Supervisor

  @doc false
  def start_link() do
    Supervisor.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    @repos
    |> Enum.map(fn repo ->
         supervisor(repo, [])
       end)
    |> Kernel.++([worker(Farmbot.Repo, [@repos])])
    |> supervise(strategy: :one_for_one)
  end
end
